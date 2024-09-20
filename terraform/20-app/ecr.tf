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
