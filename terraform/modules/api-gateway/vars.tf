variable "name" {
  description = "The name of the API Gateway"
  type        = string

  validation {
    condition     = length(var.name) > 0
    error_message = "The 'name' variable must be a non-empty string."
  }
}

variable "description" {
  description = "The description of the API Gateway"
  type        = string
  default     = "API Gateway for the application"

  validation {
    condition     = length(var.description) > 0
    error_message = "The 'description' variable must be a non-empty string."
  }
}

variable "api_gateway_stage_name" {
  description = "The stage name for API Gateway (e.g. dev or live)"
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.api_gateway_stage_name))
    error_message = "The 'stage_name' variable must only contain alphanumeric characters, dashes, or underscores."
  }
}

variable "lambda_function_arn" {
  description = "The ARN of the Lambda function to integrate with API Gateway"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:lambda:.*:.*:function:.*$", var.lambda_function_arn))
    error_message = "The 'lambda_function_arn' must be a valid Lambda function ARN."
  }
}

variable "cognito_user_pool_arn" {
  description = "The ARN of the Cognito User Pool for authorizing requests"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:cognito-idp:.*:.*:userpool/.*$", var.cognito_user_pool_arn))
    error_message = "The 'cognito_user_pool_arn' must be a valid Cognito User Pool ARN."
  }
}

variable "region" {
  description = "The AWS region for resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.region))
    error_message = "The 'region' variable must be a valid AWS region string, e.g. 'eu-west-2'."
  }
}

variable "resource_path_part" {
  description = "The resource path part for API Gateway (e.g. 'data' or '{proxy+}')"
  type        = string
  default     = "{proxy+}"

  validation {
    condition     = can(regex("^[a-zA-Z0-9/{}+_-]+$", var.resource_path_part))
    error_message = "The 'resource_path_part' must be a valid path segment containing alphanumeric characters, slashes, curly braces, dashes, or underscores."
  }
}

variable "lambda_role_arn" {
  description = "IAM Role ARN for the Lambda function"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::\\d{12}:role/.+$", var.lambda_role_arn))
    error_message = "The 'lambda_role_arn' must be a valid IAM Role ARN."
  }
}

variable "lambda_alias" {
  description = "The alias for the Lambda function (e.g. live, dev)"
  type        = string
  default     = "live"

  validation {
    condition     = contains(["dev", "live"], var.lambda_alias)
    error_message = "Invalid alias provided. Allowed values are 'dev' or 'live'."
  }
}

variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
  validation {
    condition = can(regex("^[a-zA-Z0-9_-]+$", var.prefix))
    error_message = "Prefix must only contain letters, numbers, hyphens, or underscores."
  }
}

variable "ukhsa_tenant_id" {
  description = "UKHSA Entra ID Tenant ID"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key for encrypting secrets"
  type        = string
}


