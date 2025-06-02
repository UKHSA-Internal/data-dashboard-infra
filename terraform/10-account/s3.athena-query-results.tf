module "s3_athena_query_results" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.10.0"

  bucket = "athena-query-results-${local.account_id}"

  attach_deny_insecure_transport_policy = true
}
