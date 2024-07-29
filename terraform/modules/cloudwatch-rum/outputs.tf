output "rum_application_id" {
  description = "The `APPLICATION_ID` required for the JS snippet. Returns an empty string if `create` var is False."
  value       = var.create ? aws_rum_app_monitor.this.app_monitor_id : ""
}

output "rum_cognito_pool_id" {
  description = "The `identityPoolId` required for the JS snippet. Returns an empty string if `create` var is False."
  value       = var.create ? aws_cognito_identity_pool.this.id : ""
}
