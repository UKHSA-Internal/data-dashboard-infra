module "lambda_processor" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "7.2.1"
  function_name = "cloud-watch-streaming-metrics-processor-${local.region}"

  create         = var.create
  create_package = true
  handler        = "lambda_function.lambda_handler"
  hash_extra     = local.region
  runtime        = "python${var.python_version}"
  timeout        = 60

  source_path = [
    "${path.module}/src/splunk-aws-cloud-watch-streaming-metrics-processor/__init__.py",
    "${path.module}/src/splunk-aws-cloud-watch-streaming-metrics-processor/lambda_function.py",
    {
      path             = "${path.module}/src/splunk-aws-cloud-watch-streaming-metrics-processor/requirements.txt"
      pip_requirements = true
    }

  ]

  environment_variables = {
    SPLUNK_CLOUDWATCH_SOURCETYPE = "aws:cloudwatch:metric"
    METRICS_OUTPUT_FORMAT        = "json"
  }
}
