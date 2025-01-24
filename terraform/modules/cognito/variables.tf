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

variable "nhs_metadata_url" {
  description = "Metadata URL for NHS SAML IdP"
  type        = string
  default     = "https://auth.nhs.gov.uk"
}

variable "cobr_oidc_client_id" {
  description = "Client ID for COBR OIDC IdP"
  type        = string
}

variable "cobr_oidc_client_secret" {
  description = "Client secret for COBR OIDC IdP"
  type        = string
}

variable "cobr_oidc_issuer_url" {
  description = "Issuer URL for COBR OIDC IdP"
  type        = string
  default     = "https://auth.cobr.gov.uk"
}

variable "cobr_oidc_attributes_url" {
  description = "Attributes URL for COBR OIDC IdP"
  type        = string
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
  description = "Enable SMS functionality for Cognito (e.g. for MFA or auto-verification).. Requires sns_role_arn."
  type        = bool
  default     = false
}
