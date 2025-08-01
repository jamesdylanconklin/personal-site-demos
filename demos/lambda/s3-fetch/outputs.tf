# S3 bucket outputs
output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.content_bucket.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.content_bucket.arn
}

# Lambda function outputs
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.s3_fetch.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.s3_fetch.arn
}

output "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.s3_fetch.invoke_arn
}

# API Gateway outputs
output "api_gateway_resource" {
  description = "The API Gateway resources for s3-fetch endpoints"
  value = aws_api_gateway_resource.s3_fetch_object_key
}

# IAM role outputs
output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda_role.name
}
