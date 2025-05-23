variable "region" {
  description = "The AWS region for resources"
  type        = string
}

variable "sns_role_arn" {
  description = "ARN of the SNS role for MFA"
  type        = string
  default     = null
  validation {
    condition     = can(regex("^arn:aws:iam::\\d+:role/.+", var.sns_role_arn))
    error_message = "sns_role_arn must be a valid ARN of an IAM Role."
  }
}

variable "callback_urls" {
  description = "List of allowed callback URLs for OAuth flows"
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for url in var.callback_urls : can(regex("^(http|https)://", url))])
    error_message = "Each callback URL must start with http:// or https://"
  }
}

variable "logout_urls" {
  description = "List of allowed logout URLs for OAuth flows"
  type        = list(string)
  default     = []
}

variable "group_precedence" {
  description = "Precedence of user groups"
  type        = map(number)
  default     = {
    Admin   = 1
    Analyst = 2
    Viewer  = 3
  }
}

variable "user_pool_name" {
  description = "Name of the Cognito User Pool"
  type        = string
}

variable "client_name" {
  description = "Name of the Cognito User Pool Client"
  type        = string
}

variable "user_pool_domain" {
  description = "Domain for the Cognito User Pool"
  type        = string
}

variable "ukhsa_oidc_client_id" {
  description = "UKHSA OIDC Client ID"
  type        = string
  default     = ""
}

variable "ukhsa_oidc_client_secret" {
  description = "UKHSA OIDC Client Secret"
  type        = string
  default     = ""
}

variable "ukhsa_oidc_issuer_url" {
  description = "UKHSA OIDC Issuer URL"
  type        = string
  default     = ""
}

variable "ukhsa_oidc_attributes_url" {
  description = "UKHSA OIDC Attributes URL"
  type        = string
  default     = ""
}

variable "enable_ukhsa_oidc" {
  description = "Enable UKHSA OIDC Identity Provider"
  type        = bool
  default     = false
}

variable "lambda_role_arn" {
  description = "The ARN of the Cognito Lambda execution role"
  type        = string
}

variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
}
