variable "parent_api_id" {
  description = "The ID of the parent REST API"
  type        = string
}

variable "parent_resource_id" {
  description = "The ID of the parent resource in the REST API"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project, used for resource naming and tagging"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket to provision if absent and then fetch from"
  type        = string
}

variable "fallback_object_key" {
  description = "Default object key to use if not provided in the request"
  type        = string
  default     = "403.html"
}
