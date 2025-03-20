output "lambda_function_arn" {
  description = "The ARN of the deployed Lambda function"
  value       = aws_lambda_function.api_gateway_lambda.arn
}

output "lambda_invoke_arn" {
  description = "The ARN to invoke the Lambda function"
  value       = aws_lambda_function.api_gateway_lambda.invoke_arn
}