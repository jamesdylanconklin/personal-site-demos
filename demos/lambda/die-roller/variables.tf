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
