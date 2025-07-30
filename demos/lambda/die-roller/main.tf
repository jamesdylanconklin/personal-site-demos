# Get current AWS region and account ID
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Create Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/die-roller.zip"
}

# Lambda function for die-roller
resource "aws_lambda_function" "die_roller" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "die-roller"
  role            = aws_iam_role.die_roller_lambda_role.arn
  handler         = "handler.lambda_handler"
  runtime         = "python3.11"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  depends_on = [
    aws_iam_role_policy_attachment.die_roller_lambda_logs,
    aws_cloudwatch_log_group.die_roller,
  ]
}

# IAM role for the Lambda function
resource "aws_iam_role" "die_roller_lambda_role" {
  name = "die-roller-lambda-role"

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
}

# IAM policy attachment for basic Lambda execution
resource "aws_iam_role_policy_attachment" "die_roller_lambda_logs" {
  role       = aws_iam_role.die_roller_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# CloudWatch log group for the Lambda function
resource "aws_cloudwatch_log_group" "die_roller" {
  name              = "/aws/lambda/die-roller"
  retention_in_days = 14
}

# Lambda permission to allow API Gateway to invoke the function
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.die_roller.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${var.parent_api_id}/*/*"
}

# API Gateway Resource for die-roller
resource "aws_api_gateway_resource" "die_roller" {
  rest_api_id = var.parent_api_id
  parent_id   = var.parent_resource_id
  path_part   = "roll"
}

# API Gateway Resource for die-roller with roll string path parameter
resource "aws_api_gateway_resource" "die_roller_roll_string" {
  rest_api_id = var.parent_api_id
  parent_id   = aws_api_gateway_resource.die_roller.id
  path_part   = "{rollString}"
}

# API Gateway Method for GET /roll/{rollString}
resource "aws_api_gateway_method" "die_roller_get" {
  rest_api_id   = var.parent_api_id
  resource_id   = aws_api_gateway_resource.die_roller_roll_string.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.rollString" = true
  }
}

# API Gateway Method for GET /roll (empty roll string)
resource "aws_api_gateway_method" "die_roller_get_empty" {
  rest_api_id   = var.parent_api_id
  resource_id   = aws_api_gateway_resource.die_roller.id
  http_method   = "GET"
  authorization = "NONE"
}

# API Gateway Integration for /roll/{rollString}
resource "aws_api_gateway_integration" "die_roller_integration" {
  rest_api_id = var.parent_api_id
  resource_id = aws_api_gateway_resource.die_roller_roll_string.id
  http_method = aws_api_gateway_method.die_roller_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.die_roller.invoke_arn

  request_parameters = {
    "integration.request.path.rollString" = "method.request.path.rollString"
  }
}

# API Gateway Integration for /roll (empty)
resource "aws_api_gateway_integration" "die_roller_integration_empty" {
  rest_api_id = var.parent_api_id
  resource_id = aws_api_gateway_resource.die_roller.id
  http_method = aws_api_gateway_method.die_roller_get_empty.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.die_roller.invoke_arn
}

# API Gateway Method Response for /roll/{rollString}
resource "aws_api_gateway_method_response" "die_roller_response_200" {
  rest_api_id = var.parent_api_id
  resource_id = aws_api_gateway_resource.die_roller_roll_string.id
  http_method = aws_api_gateway_method.die_roller_get.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "die_roller_response_400" {
  rest_api_id = var.parent_api_id
  resource_id = aws_api_gateway_resource.die_roller_roll_string.id
  http_method = aws_api_gateway_method.die_roller_get.http_method
  status_code = "400"

  response_models = {
    "application/json" = "Error"
  }
}

# API Gateway Method Response for /roll (empty)
resource "aws_api_gateway_method_response" "die_roller_response_200_empty" {
  rest_api_id = var.parent_api_id
  resource_id = aws_api_gateway_resource.die_roller.id
  http_method = aws_api_gateway_method.die_roller_get_empty.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "die_roller_response_400_empty" {
  rest_api_id = var.parent_api_id
  resource_id = aws_api_gateway_resource.die_roller.id
  http_method = aws_api_gateway_method.die_roller_get_empty.http_method
  status_code = "400"

  response_models = {
    "application/json" = "Error"
  }
}

# API Gateway Integration Response for /roll/{rollString}
resource "aws_api_gateway_integration_response" "die_roller_integration_response_200" {
  rest_api_id = var.parent_api_id
  resource_id = aws_api_gateway_resource.die_roller_roll_string.id
  http_method = aws_api_gateway_method.die_roller_get.http_method
  status_code = aws_api_gateway_method_response.die_roller_response_200.status_code

  depends_on = [aws_api_gateway_integration.die_roller_integration]
}

resource "aws_api_gateway_integration_response" "die_roller_integration_response_400" {
  rest_api_id = var.parent_api_id
  resource_id = aws_api_gateway_resource.die_roller_roll_string.id
  http_method = aws_api_gateway_method.die_roller_get.http_method
  status_code = aws_api_gateway_method_response.die_roller_response_400.status_code

  selection_pattern = "4\\d{2}"

  depends_on = [aws_api_gateway_integration.die_roller_integration]
}

# API Gateway Integration Response for /roll (empty)
resource "aws_api_gateway_integration_response" "die_roller_integration_response_200_empty" {
  rest_api_id = var.parent_api_id
  resource_id = aws_api_gateway_resource.die_roller.id
  http_method = aws_api_gateway_method.die_roller_get_empty.http_method
  status_code = aws_api_gateway_method_response.die_roller_response_200_empty.status_code

  depends_on = [aws_api_gateway_integration.die_roller_integration_empty]
}

resource "aws_api_gateway_integration_response" "die_roller_integration_response_400_empty" {
  rest_api_id = var.parent_api_id
  resource_id = aws_api_gateway_resource.die_roller.id
  http_method = aws_api_gateway_method.die_roller_get_empty.http_method
  status_code = aws_api_gateway_method_response.die_roller_response_400_empty.status_code

  selection_pattern = "4\\d{2}"

  depends_on = [aws_api_gateway_integration.die_roller_integration_empty]
}
