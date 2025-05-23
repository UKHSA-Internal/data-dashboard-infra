variable "region" {
  description = "The AWS region for resources"
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

variable "ukhsa_client_id" {
  type        = string
  description = "Azure UKHSA Application Client ID"
  sensitive   = true
}

variable "ukhsa_client_secret" {
  type        = string
  description = "Azure UKHSA Application Client Secret"
  sensitive   = true
}

variable "ukhsa_tenant_id" {
  description = "UKHSA Entra ID Tenant ID"
  type        = string
  sensitive   = true
}

variable "enable_ukhsa_oidc" {
  description = "Enable UKHSA OIDC Identity Provider"
  type        = bool
  default     = false
}

variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
}


