module "ecr_ingestion" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.3.0"

  repository_force_delete            = true
  repository_image_tag_mutability    = "MUTABLE"
  repository_name                    = "${local.prefix}-ingestion"
  repository_read_access_arns        = ["arn:aws:iam::${var.assume_account_id}:root"]
  repository_read_write_access_arns  = ["arn:aws:iam::${var.tools_account_id}:root"]
  repository_lambda_read_access_arns = [module.lambda_ingestion.lambda_role_arn]

  create_lifecycle_policy     = true
}

module "ecr_front_end_ecs" {
  source = "../modules/ecr"
  name   = "${local.prefix}-front-end-ecs"

  account_id       = var.assume_account_id
  tools_account_id = var.tools_account_id
}

module "ecr_back_end_ecs" {
  source = "../modules/ecr"
  name   = "${local.prefix}-back-end-ecs"

  account_id       = var.assume_account_id
  tools_account_id = var.tools_account_id
}

module "ecr_ingestion_lambda" {
  source = "../modules/ecr"
  name   = "${local.prefix}-ingestion-lambda"

  account_id                         = var.assume_account_id
  tools_account_id                   = var.tools_account_id
  repository_lambda_read_access_arns = [module.lambda_ingestion.lambda_role_arn]
}
