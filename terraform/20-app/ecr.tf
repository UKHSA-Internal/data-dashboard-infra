module "ecr_front_end" {
  source = "../modules/image-repo"
  name   = "${local.prefix}-front-end"

  account_id       = var.assume_account_id
  tools_account_id = var.tools_account_id
}

module "ecr_api" {
  source = "../modules/image-repo"
  name   = "${local.prefix}-api"

  account_id       = var.assume_account_id
  tools_account_id = var.tools_account_id
}

module "ecr_ingestion" {
  source = "../modules/image-repo"
  name   = "${local.prefix}-ingestion"

  account_id                         = var.assume_account_id
  tools_account_id                   = var.tools_account_id
  repository_lambda_read_access_arns = [module.lambda_ingestion.lambda_role_arn]
}
