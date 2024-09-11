module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.2.0"

  repository_force_delete           = true
  repository_image_tag_mutability   = "IMMUTABLE"
  repository_name                   = var.name
  repository_read_access_arns       = ["arn:aws:iam::${var.account_id}:root"]
  repository_read_write_access_arns = ["arn:aws:iam::${var.tools_account_id}:root"]

  create_lifecycle_policy     = true
  repository_lifecycle_policy = local.standard_ecr_lifecycle_policy
}
