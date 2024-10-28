variable "name" {
  description = "The name of the repository"
  type        = string
  default     = ""
}

variable "account_id" {
  description = "The ID of the AWS account in which the ECR is being vended to."
  type        = string
  default     = ""
}

variable "tools_account_id" {
  description = "The ID of the tools AWS account."
  type        = string
  default     = ""
}

variable "repository_lambda_read_access_arns" {
  description = "The ARNs of the Lambda service roles that have read access to the repository"
  type        = list(string)
  default     = []
}
