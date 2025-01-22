variable "user_pool_name" {
  description = "The name of the Cognito User Pool"
  type        = string
}

variable "client_name" {
  description = "The name of the Cognito User Pool Client"
  type        = string
}

variable "user_pool_domain" {
  description = "The domain prefix for Cognito User Pool"
  type        = string
  default     = null
}

variable "callback_urls" {
  description = "A list of allowed callback URLs for the User Pool Client"
  type        = list(string)
  default     = []
}

variable "logout_urls" {
  description = "A list of allowed logout URLs for the User Pool Client"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}