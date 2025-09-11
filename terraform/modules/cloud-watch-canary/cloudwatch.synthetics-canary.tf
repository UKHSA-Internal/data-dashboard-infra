resource "aws_synthetics_canary" "this" {
  count = var.create ? 1 : 0
  name  = var.name

  artifact_s3_location = "s3://${module.s3_canary_logs.s3_bucket_id}"
  execution_role_arn   = module.iam_canary_role.iam_role_arn
  zip_file             = data.archive_file.canary_script.output_path
  handler              = "index.handler"
  runtime_version      = "syn-nodejs-puppeteer-9.0"
  start_canary         = true
  delete_lambda        = true

  schedule {
    expression = var.schedule_expression
  }

  vpc_config {
    subnet_ids = var.subnet_ids
    security_group_ids = [module.canary_security_group.security_group_id]
  }

  run_config {
    timeout_in_seconds    = var.timeout_in_seconds
    environment_variables = var.environment_variables
  }

  success_retention_period = 1
  failure_retention_period = 14
}
