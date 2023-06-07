moved {
  from = aws_ecr_repository.api
  to   = module.ecr_api.aws_ecr_repository.this[0]
}

moved {
  from = aws_ecr_repository.frontend
  to   = module.ecr_front_end.aws_ecr_repository.this[0]
}

module "ecr_api" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "1.6.0"

  create_lifecycle_policy           = false
  repository_image_tag_mutability   = "MUTABLE"
  repository_name                   = "${local.prefix}-api"
  repository_read_write_access_arns = ["arn:aws:iam::${var.tools_account_id}:root"]
  repository_read_access_arns       = ["arn:aws:iam::${var.assume_account_id}:root"]
}

module "ecr_front_end" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "1.6.0"

  create_lifecycle_policy           = false
  repository_image_tag_mutability   = "MUTABLE"
  repository_name                   = "${local.prefix}-front-end"
  repository_read_access_arns       = ["arn:aws:iam::${var.assume_account_id}:root"]
  repository_read_write_access_arns = ["arn:aws:iam::${var.tools_account_id}:root"]

}
