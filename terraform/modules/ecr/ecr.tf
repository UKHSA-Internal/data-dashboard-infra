module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.3.0"

  repository_force_delete           = true
  repository_image_tag_mutability   = "IMMUTABLE"
  repository_name                   = var.name
  repository_read_access_arns       = ["arn:aws:iam::${var.account_id}:root"]
  repository_read_write_access_arns = ["arn:aws:iam::${var.tools_account_id}:root"]

  create_lifecycle_policy     = true
  repository_lifecycle_policy = local.standard_ecr_lifecycle_policy

  # aws usually adds a global `LambdaECRImageRetrievalPolicy` policy automatically when the lambda is invoked and
  # attempts to pull the image, but sometimes this doesn't apparently and then the lambda fails to pull the image. This
  # policy is added to ensure that the lambda can always pull the image from ECR. This is only applied for lambda
  # repositories.
  repository_policy = length(var.repository_lambda_read_access_arns) > 0 ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LambdaRoleECRAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.repository_lambda_read_access_arns
        }
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      }
    ]
  }) : null
}
