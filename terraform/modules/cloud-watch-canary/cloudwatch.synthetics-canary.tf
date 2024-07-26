resource "aws_synthetics_canary" "this" {
  name                 = var.name
  artifact_s3_location = "s3://${var.s3_logs_destination.bucket_id}"
  execution_role_arn   = module.iam_canary_role.iam_role_arn
  zip_file             = data.archive_file.canary_script.output_path
  handler              = "index.handler"
  runtime_version      = "syn-nodejs-puppeteer-8.0"
  start_canary         = true
  delete_lambda        = true

  schedule {
    expression = var.schedule_expression
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [module.canary_security_group.security_group_id]
  }
}
