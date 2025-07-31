# Get current AWS region and account ID
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Common tags for all resources
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Component   = "s3-fetcher"
  }
}

# S3 bucket for storing objects to fetch
resource "aws_s3_bucket" "content_bucket" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = merge(local.common_tags, {
    Name = var.bucket_name
  })
}

# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "content_bucket_pab" {
  bucket = aws_s3_bucket.content_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable default encryption for the bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "content_bucket_encryption" {
  bucket = aws_s3_bucket.content_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Upload 403.html error page to S3 bucket
resource "aws_s3_object" "error_403" {
  bucket       = aws_s3_bucket.content_bucket.bucket
  key          = "403.html"
  source       = "${path.module}/assets/403.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/assets/403.html")

  tags = merge(local.common_tags, {
    Name = "403-error-page"
  })
}

# Build TypeScript Lambda function
resource "null_resource" "build_typescript" {
  triggers = {
    handler_hash     = filemd5("${path.module}/src/handler.ts")
    tsconfig_hash    = filemd5("${path.module}/src/tsconfig.json")
    package_hash     = filemd5("${path.module}/src/package.json")
    # Force rebuild when node_modules doesn't exist
    node_modules_check = fileexists("${path.module}/src/node_modules/package-lock.json") ? "exists" : uuid()
  }

  provisioner "local-exec" {
    command = "cd ${path.module}/src && npm install"
  }

  provisioner "local-exec" {
    command = "cd ${path.module}/src && npm run build"
  }
}

# Package Lambda function into zip file
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/dist"
  output_path = "${path.module}/lambda-deployment.zip"
  
  depends_on = [null_resource.build_typescript]
}

# IAM role for Lambda execution
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-s3-fetch-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# IAM policy for S3 access
resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "${var.project_name}-${var.environment}-s3-fetch-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.content_bucket.arn,
          "${aws_s3_bucket.content_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Lambda function
resource "aws_lambda_function" "s3_fetch" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-${var.environment}-s3-fetch"
  role            = aws_iam_role.lambda_role.arn
  handler         = "handler.handler"
  runtime         = "nodejs22.x"
  timeout         = 30
  
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.content_bucket.bucket
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-s3-fetch"
  })
}

# API Gateway resource for the Lambda function
resource "aws_api_gateway_resource" "s3_fetch_resource" {
  rest_api_id = var.parent_api_id
  parent_id   = var.parent_resource_id
  path_part   = "s3-fetch"
}

# API Gateway resource for file path (objectKey)
resource "aws_api_gateway_resource" "s3_fetch_object_key" {
  rest_api_id = var.parent_api_id
  parent_id   = aws_api_gateway_resource.s3_fetch_resource.id
  path_part   = "{objectKey}"
}

# API Gateway method for GET requests
resource "aws_api_gateway_method" "s3_fetch_get" {
  rest_api_id   = var.parent_api_id
  resource_id   = aws_api_gateway_resource.s3_fetch_object_key.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.objectKey" = true
  }
}

# API Gateway integration with Lambda
resource "aws_api_gateway_integration" "s3_fetch_integration" {
  rest_api_id = var.parent_api_id
  resource_id = aws_api_gateway_resource.s3_fetch_object_key.id
  http_method = aws_api_gateway_method.s3_fetch_get.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.s3_fetch.invoke_arn

  request_parameters = {
    "integration.request.path.objectKey" = "method.request.path.objectKey"
  }
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_fetch.function_name
  principal     = "apigateway.amazonaws.com"

  # Use wildcard source ARN to avoid path issues
  source_arn = "arn:aws:execute-api:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${var.parent_api_id}/*/${aws_api_gateway_method.s3_fetch_get.http_method}${aws_api_gateway_resource.s3_fetch_object_key.path}/*"

  # source_arn = "arn:aws:execute-api:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${var.parent_api_id}/*/*"
}
