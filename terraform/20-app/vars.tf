variable "assume_account_id" {
  sensitive = true
}

variable "assume_role_name" {
  default = "TerraformOperator"
}

variable "azs" {
  default = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

variable "environment_type" {}

variable "one_nat_gateway_per_az" {
  default = false
}

variable "python_version" {}

variable "tools_account_id" {
  sensitive = true
}

variable "etl_account_id" {
  sensitive = true
}

variable "ukhsa_tenant_id" {
  sensitive = true
}

variable "ukhsa_client_id" {
  sensitive = true
}

variable "ukhsa_client_secret" {
  sensitive = true
}

variable "single_nat_gateway" {
  default = true
}

variable "halo_account_type" {}

variable "auth_enabled" {}

variable "api_gateway_stage_name" {
  description = "The stage name for API Gateway (e.g. dev or live)"
  type        = string
  default     = "dev"
}

variable "cognito_admin_email" {
  description = "Admin email address for Cognito SNS notifications"
  type        = string
  default     = "Christian.Martin@ukhsa.gov.uk"
}

variable "client_id" {
  description = "Client ID for Cognito integration"
  type        = string
  default     = ""
  sensitive   = true
}

variable "client_secret" {
  description = "Client Secret for Cognito integration"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cognito_user_pool_issuer_endpoint" {
  description = "The issuer endpoint for the Cognito user pool (e.g. https://cognito-idp.<region>.amazonaws.com/<user_pool_id>)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ukhsa_tenant_id" {
  description = "UKHSA Entra ID Tenant ID"
  type        = string
  default     = ""
  sensitive   = true
}