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

variable "single_nat_gateway" {
  default = true
}

variable "halo_account_type" {}

variable "api_gateway_stage_name" {
  description = "The stage name for API Gateway (e.g. dev or live)"
  type        = string
  default     = "dev"
}

variable "cognito_admin_email" {
  description = "Admin email address for Cognito SNS notifications"
  type        = string
  default     = "Afaan.Ashiq@ukhsa.gov.uk"
}

variable "ukhsa_oidc_client_id" {
  description = "UKHSA OIDC Client ID for Cognito"
  type        = string
}

variable "ukhsa_oidc_client_secret" {
  description = "UKHSA OIDC Client Secret for Cognito"
  type        = string
}

variable "ukhsa_tenant_id" {
  description = "UKHSA Entra ID Tenant ID"
  type        = string
}
