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

output "cognito_oauth_url" {
  description = "The Cognito User Pool OAuth URL"
  value       = "https://${aws_cognito_user_pool_domain.cognito_user_pool_domain.domain}.auth.${var.region}.amazoncognito.com"
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

output "client_id" {
  description = "The Cognito User Pool App Client ID"
  value       = aws_cognito_user_pool_client.user_pool_client.id
}

output "client_secret" {
  description = "The Client Secret for Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.user_pool_client.client_secret
  sensitive   = true
}

output "cognito_user_pool_issuer_endpoint" {
  description = "The Issuer API Endpoint for Cognito User Pool"
  value       = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.user_pool.id}"
  sensitive   = true
}

output "cognito_lambda_role_arn" {
  description = "The ARN of the Cognito Lambda execution role"
  value       = var.lambda_role_arn
}

output "tenant_id" {
  description = "The UKHSA tenant ID used for OIDC"
  value       = var.ukhsa_tenant_id
  sensitive   = true
}
