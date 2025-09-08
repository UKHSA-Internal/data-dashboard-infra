resource "aws_iam_role" "cognito_sns_role" {
  name = "${var.prefix}-cognito-sns"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cognito-idp.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "cognito_sns_policy" {
  name        = "${var.prefix}-cognito-sns"
  description = "Allows Cognito to publish messages to the SNS topic"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCognitoToPublish",
        Effect = "Allow",
        Action = ["sns:Publish"],
        Resource = module.cognito_sns.topic_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cognito_sns_policy_attachment" {
  role       = aws_iam_role.cognito_sns_role.id
  policy_arn = aws_iam_policy.cognito_sns_policy.arn
}

resource "aws_iam_role" "cognito_lambda_role" {
  name = "${var.prefix}-cognito-lambda-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}