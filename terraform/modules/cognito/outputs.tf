output "user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.user_pool.id
}

output "user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.user_pool_client.id
}

output "user_pool_domain" {
  description = "The Cognito User Pool domain"
  value       = aws_cognito_user_pool_domain.user_pool_domain.domain
}

