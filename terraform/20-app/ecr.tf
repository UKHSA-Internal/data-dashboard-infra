moved {
  from = aws_ecr_repository.api
  to   = module.ecr_api.aws_ecr_repository.this[0]
}

moved {
  from = aws_ecr_repository.frontend
  to   = module.ecr_front_end.aws_ecr_repository.this[0]
}

module "ecr_front_end" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "1.6.0"

  create_lifecycle_policy           = false
  repository_force_delete           = true
  repository_image_tag_mutability   = "MUTABLE"
  repository_name                   = "${local.prefix}-front-end"
  repository_read_access_arns       = ["arn:aws:iam::${var.assume_account_id}:root"]
  repository_read_write_access_arns = ["arn:aws:iam::${var.tools_account_id}:root"]

}

module "ecr_api" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "1.6.0"

  create_lifecycle_policy           = false
  repository_force_delete           = true
  repository_image_tag_mutability   = "MUTABLE"
  repository_name                   = "${local.prefix}-api"
  repository_read_access_arns       = ["arn:aws:iam::${var.assume_account_id}:root"]
  repository_read_write_access_arns = ["arn:aws:iam::${var.tools_account_id}:root"]
}


# This is a 1-time execution script to put a dummy image into the ingestion ECR repo
# So that when the ingestion lambda function is provisioned by terraform,
# there will be an image available to pull
resource "terraform_data" "dummy_ingestion_image_provisioner" {
  depends_on = [module.ecr_ingestion]
  provisioner "local-exec" {
    command = <<EOF
      docker login
      docker pull alpine
      docker tag alpine ${module.ecr_ingestion.repository_url}:latest
      docker push ${module.ecr_ingestion.repository_url}:latest
    EOF
  }
}

module "ecr_ingestion" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "1.6.0"

  repository_force_delete            = true
  repository_image_tag_mutability    = "MUTABLE"
  repository_name                    = "${local.prefix}-ingestion"
  repository_read_access_arns        = ["arn:aws:iam::${var.assume_account_id}:root"]
  repository_read_write_access_arns  = ["arn:aws:iam::${var.tools_account_id}:root"]
  repository_lambda_read_access_arns = [module.lambda_ingestion.lambda_role_arn]

  create_lifecycle_policy     = true
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 10 images",
        selection    = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = 10
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}
