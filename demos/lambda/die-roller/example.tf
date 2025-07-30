# Example usage of the die-roller API Gateway module
#
# This would typically be called from a parent Terraform configuration
# that manages the main API Gateway

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

module "die_roller_api" {
  source = "./demos/lambda/die-roller"

  parent_api_id       = aws_api_gateway_rest_api.main.id
  parent_resource_id  = aws_api_gateway_rest_api.main.root_resource_id
}

# The module includes everything needed:
# - Automatic zipping of source code from src/ directory
# - Lambda function with all dependencies
# - IAM role and permissions
# - CloudWatch log group
# - API Gateway resources and integrations
