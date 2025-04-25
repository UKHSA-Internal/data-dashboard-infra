output "api_gateway_id" {
  description = "The ID of the API Gateway"
  value       = aws_api_gateway_rest_api.api_gateway.id
}

output "api_gateway_url" {
  description = "The invoke URL of the API Gateway"
  value       = aws_api_gateway_deployment.deployment.invoke_url
}

output "api_gateway_stage_name" {
  description = "The stage name of the API Gateway deployment"
  value       = aws_api_gateway_stage.stage.stage_name
}

output "api_gateway_lambda_invoke_arn" {
  description = "The invoke ARN for the API Gateway Lambda function alias"
  value       = var.lambda_alias == "live" ? aws_lambda_alias.live.arn : aws_lambda_alias.dev.arn
}

output "lambda_alias_arn" {
  description = "The ARN of the selected Lambda alias"
  value       = lookup({
    "live" = aws_lambda_alias.live.arn,
    "dev"  = aws_lambda_alias.dev.arn
  }, var.lambda_alias, aws_lambda_alias.live.arn)
}

output "api_gateway_lambda_arn" {
  description = "The ARN of the API Gateway Lambda function"
  value       = aws_lambda_function.api_gateway_lambda.arn
}