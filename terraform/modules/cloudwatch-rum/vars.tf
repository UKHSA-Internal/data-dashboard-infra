variable "create" {
  description = "Whether to create Cloudwatch RUM and its associated components"
  type        = bool
  default     = true
}

variable "name" {
  description = "The name to associate with the Cloudwatch RUM components"
  type        = string
}

variable "domain_name" {
  description = "The domain to attach the Cloudwatch RUM monitor to"
  type        = string
}

variable "session_sample_rate" {
  description = "The proportion of user sessions to collect. Defaults to 1.0 which means 100%"
  type        = number
  default     = 1.0
}
