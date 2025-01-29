output "cognito_user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.user_pool.id
  sensitive   = true
}

output "cognito_user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.user_pool_client.id
  sensitive   = true
}

output "cognito_user_pool_domain" {
  description = "The domain prefix for the Cognito User Pool"
  value       = aws_cognito_user_pool_domain.cognito_user_pool_domain.domain
  sensitive   = true
}

output "cognito_oauth_authorize_url" {
  description = "The Cognito User Pool OAuth authorize URL"
  value       = "https://${aws_cognito_user_pool_domain.cognito_user_pool_domain.domain}.auth.${var.region}.amazoncognito.com/oauth2/authorize"
  sensitive   = true
}

output "cognito_oauth_logout_url" {
  description = "The Cognito User Pool OAuth logout URL"
  value       = "https://${aws_cognito_user_pool_domain.cognito_user_pool_domain.domain}.auth.${var.region}.amazoncognito.com/logout"
  sensitive   = true
}

output "cognito_oauth_token_url" {
  description = "The Cognito User Pool OAuth token URL"
  value       = "https://${aws_cognito_user_pool_domain.cognito_user_pool_domain.domain}.auth.${var.region}.amazoncognito.com/oauth2/token"
  sensitive   = true
}

output "cognito_oauth_userinfo_url" {
  description = "The Cognito User Pool OAuth userinfo URL"
  value       = "https://${aws_cognito_user_pool_domain.cognito_user_pool_domain.domain}.auth.${var.region}.amazoncognito.com/oauth2/userInfo"
  sensitive   = true
}

output "cognito_user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.user_pool.arn
  sensitive   = true
}

output "cognito_lambda_role_arn" {
  description = "The ARN of the Cognito Lambda execution role"
  value       = aws_iam_role.cognito_lambda_role.arn
}
