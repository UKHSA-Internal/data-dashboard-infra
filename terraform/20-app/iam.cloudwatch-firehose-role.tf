resource "aws_iam_role" "cloudwatch_to_firehose_role" {
  name = "${local.prefix}-cloudwatch_to_firehose_audit_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "logs.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "cloudwatch_to_firehose_policy" {
  name = "${local.prefix}-cloudwatch_firehose_audit_policy"
  role = aws_iam_role.cloudwatch_to_firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "firehose:PutRecord"
      Effect   = "Allow"
      Resource = aws_kinesis_firehose_delivery_stream.audit_stream.arn
    }]
  })
}
