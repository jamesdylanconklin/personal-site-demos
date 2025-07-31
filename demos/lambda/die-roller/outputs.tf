output "api_gateway_resources" {
  description = "The API Gateway resources for die roller endpoints"
  value = {
    roll_basic = aws_api_gateway_resource.die_roller
    roll_with_params = aws_api_gateway_resource.die_roller_roll_string
  }
}

output "die_roller_execution_arn" {
  description = "The execution ARN for the die roller endpoints"
  value       = "arn:aws:execute-api:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${var.parent_api_id}/*/*"
}

output "lambda_function_name" {
  description = "The name of the die-roller Lambda function"
  value       = aws_lambda_function.die_roller.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the die-roller Lambda function"
  value       = aws_lambda_function.die_roller.arn
}
