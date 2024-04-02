module "lambda_processor" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "7.2.5"
  function_name = "cloud-watch-streaming-logs-processor-${local.region}"

  create_package = true
  handler        = "lambda_function.lambda_handler"
  hash_extra     = local.region
  runtime        = "python${var.python_version}"
  timeout        = 60

  source_path = [
    "${path.module}/src/splunk-aws-cloud-watch-streaming-logs-processor/lambda_function.py"
  ]
}
