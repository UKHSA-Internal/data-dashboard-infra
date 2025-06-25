module "ecr_test_automation" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.3.0"

  repository_name                   = "${local.prefix}-test-automation"
  repository_image_tag_mutability   = "MUTABLE"
  repository_force_delete           = true
  repository_read_access_arns       = ["arn:aws:iam::${local.account_id}:root"]
  repository_read_write_access_arns = ["arn:aws:iam::${var.tools_account_id}:root"]

  create_lifecycle_policy     = true
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep the last 5 images",
        selection    = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = 5
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}
