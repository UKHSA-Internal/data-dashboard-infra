resource "aws_iam_role" "firehose_role" {
  name = "${local.prefix}-audit_log_firehose_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "firehose.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "firehose_s3_policy" {
  name = "${local.prefix}-firehose_s3_policy"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject"
      ]
      Effect   = "Allow"
      Resource = [
        module.s3_audit_logs.s3_bucket_arn,
        "${module.s3_audit_logs.s3_bucket_arn}/*"
      ]
    }]
  })
}
