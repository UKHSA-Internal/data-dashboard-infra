variable "create" {
  description = "Whether to create the synthetic canary and its associated components"
  type        = bool
  default     = true
}

variable "name" {
  description = "The name to associate with the synthetic canary components"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy the canary within"
  type        = string
}

variable "s3_access_logs_id" {
  description = "The ID of the S3 bucket where access logs are sent to"
  type        = string
}

variable "subnet_ids" {
  description = "The IDs of the subnets where this canary is to run."
  type = list(string)
}

variable "schedule_expression" {
  description = "The cron schedule expression to apply to the canary."
  type        = string
}

variable "timeout_in_seconds" {
  description = "The number of seconds which the canary should run until timing out."
  type        = number
}

variable "src_script_filename" {
  description = "The file name of the script to attach to the canary"
  type        = string
}

variable "environment_variables" {
  description = "Map of environment variables to provide to the canary runtime."
  type = map(string)
  default = {}
}

variable "slack_webhook_url_secret_arn" {
  description = "The ARN of the secret containing the slack webhook URL"
}
