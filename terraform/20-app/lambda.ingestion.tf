module "lambda_ingestion" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "7.2.3"
  function_name = "${local.prefix}-ingestion"
  description   = "Consumes records from the Kinesis data stream."

  vpc_subnet_ids         = module.vpc.private_subnets
  vpc_security_group_ids = [module.lambda_ingestion_security_group.security_group_id]
  attach_network_policy  = true

  cloudwatch_logs_retention_in_days = local.default_log_retention_in_days

  create_package = false
  package_type   = "Image"
  architectures  = ["arm64"]
  image_uri      = "${module.ecr_ingestion.repository_url}:latest"
  depends_on     = [module.ecr_ingestion.repository_arn]

  maximum_retry_attempts = 1
  timeout                = 60 # Timeout after 1 minute
  memory_size            = 256

  event_source_mapping = {
    kinesis = {
      event_source_arn       = aws_kinesis_stream.kinesis_data_stream_ingestion.arn
      starting_position      = "LATEST"
      batch_size             = 1
      retry_attempts         = 1
      parallelization_factor = 10
      enabled                = true
    }
  }

  environment_variables = {
    INGESTION_BUCKET_NAME              = module.s3_ingest.s3_bucket_id
    POSTGRES_DB                        = local.rds.app.primary.db_name
    POSTGRES_HOST                      = module.rds_proxy.proxy_endpoint
    POSTGRES_USER                      = jsondecode(aws_secretsmanager_secret_version.rds_db_creds.secret_string)["username"]
    SECRETS_MANAGER_DB_CREDENTIALS_ARN = aws_secretsmanager_secret.rds_db_creds.arn
    APIENV                             = "PROD"
    APP_MODE                           = "INGESTION"
  }

  attach_policy_statements = true
  policy_statements        = {
    move_items_from_in_folder_of_ingest_bucket = {
      actions   = ["s3:GetObject", "s3:DeleteObject"]
      effect    = "Allow"
      resources = ["${module.s3_ingest.s3_bucket_arn}/in/*"]
    }
    add_items_to_processed_folder_of_ingest_bucket = {
      actions   = ["s3:PutObject"]
      effect    = "Allow"
      resources = ["${module.s3_ingest.s3_bucket_arn}/processed/*"]
    }
    add_files_to_failed_folder_of_ingest_bucket = {
      actions   = ["s3:PutObject"]
      effect    = "Allow"
      resources = ["${module.s3_ingest.s3_bucket_arn}/failed/*"]
    }
    get_db_credentials_from_secrets_manager = {
      effect    = "Allow",
      actions   = ["secretsmanager:GetSecretValue"],
      resources = [aws_secretsmanager_secret.rds_db_creds.arn]
    }
    read_from_kinesis = {
      effect  = "Allow"
      actions = [
        "kinesis:GetRecords",
        "kinesis:GetShardIterator",
        "kinesis:ListStreams",
        "kinesis:ListShards",
        "kinesis:DescribeStream",
        "kinesis:DescribeStreamSummary",
      ]
      resources = [aws_kinesis_stream.kinesis_data_stream_ingestion.arn]
    }
  }
}


module "lambda_ingestion_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name   = "${local.prefix}-lambda-ingestion"
  vpc_id = module.vpc.vpc_id

  egress_with_cidr_blocks = [
    {
      description = "https to internet"
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_source_security_group_id = [
    {
      description              = "ingestion lambda to proxy"
      rule                     = "postgresql-tcp"
      source_security_group_id = module.rds_proxy_security_group.security_group_id
    }
  ]
}

resource "aws_cloudwatch_log_subscription_filter" "lambda_ingestion" {
  count = local.ship_cloud_watch_logs_to_splunk ? 1 : 0

  destination_arn = local.account_layer.kinesis.cloud_watch_logs_to_splunk.eu_west_2.destination_arn
  filter_pattern  = ""
  log_group_name  = module.lambda_ingestion.lambda_cloudwatch_log_group_name
  name            = "splunk"
  role_arn        = local.account_layer.kinesis.cloud_watch_logs_to_splunk.eu_west_2.role_arn
}
