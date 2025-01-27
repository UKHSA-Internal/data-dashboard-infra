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

variable "metadata_url" {
  description = "Metadata URL for NHS SAML IdP"
  type        = string
  default     = "https://auth.nhs.gov.uk"
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

variable "enable_mfa" {
  description = "Enable Multi-Factor Authentication (MFA) for Cognito. If true, MFA will be enforced."
  type        = bool
  default     = false
}

variable "enable_sms" {
  description = "Enable SMS functionality for Cognito (e.g. for MFA or auto-verification). Requires sns_role_arn."
  type        = bool
  default     = false
}

variable "enable_saml" {
  description = "Enable SAML integration"
  type        = bool
  default     = false
}

variable "saml_metadata_url" {
  description = "URL for SAML metadata"
  type        = string
  default     = ""
}

variable "saml_logout_url" {
  description = "SAML logout URL"
  type        = string
  default     = ""
}

variable "enable_oidc" {
  description = "Enable OIDC integration"
  type        = bool
  default     = false
}

variable "oidc_client_id" {
  description = "OIDC Client ID"
  type        = string
  default     = ""
}

variable "oidc_client_secret" {
  description = "OIDC Client Secret"
  type        = string
  default     = ""
}

variable "oidc_issuer_url" {
  description = "OIDC Issuer URL"
  type        = string
  default     = ""
}

variable "oidc_attributes_url" {
  description = "OIDC Attributes URL"
  type        = string
  default     = ""
}