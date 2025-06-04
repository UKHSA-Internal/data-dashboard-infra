output "api_gateway_id" {
  description = "The ID of the API Gateway"
  value       = aws_api_gateway_rest_api.api_gateway.id
}

output "api_gateway_url" {
  description = "The invoke URL of the API Gateway"
  value       = aws_api_gateway_stage.stage.invoke_url
}

output "api_gateway_stage_name" {
  description = "The stage name of the API Gateway deployment"
  value       = aws_api_gateway_stage.stage.stage_name
}
