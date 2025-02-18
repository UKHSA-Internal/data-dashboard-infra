resource "aws_api_gateway_account" "account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role.arn

  depends_on = [
    aws_iam_role.api_gateway_cloudwatch_role,
    aws_iam_role_policy.api_gateway_cloudwatch_policy
  ]
}

resource "aws_iam_role" "api_gateway_cloudwatch_role" {
  name = "${var.prefix}-api-gateway-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "api_gateway_cloudwatch_policy" {
  role = aws_iam_role.api_gateway_cloudwatch_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ],
        Resource = [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/apigateway/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "apigateway:GET",
          "apigateway:PUT",
          "apigateway:POST",
          "apigateway:DELETE",
          "apigateway:PATCH"
        ],
        Resource = aws_api_gateway_rest_api.api_gateway.execution_arn
      }
    ]
  })
}