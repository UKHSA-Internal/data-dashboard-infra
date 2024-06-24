output "arn" {
  description = "The ARN of the Cloudfront function"
  value       = var.create ? aws_cloudfront_function.password_protection[0].arn : ""
}
