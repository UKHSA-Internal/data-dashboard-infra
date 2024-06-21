variable "create" {
  description = "Whether to create the Cloudfront function and KV store"
  type        = bool
  default     = false
}

variable "name" {
  description = "The name to associate with the Cloudfront components"
  type        = string
}
