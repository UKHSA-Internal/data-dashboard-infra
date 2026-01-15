module "s3_athena_query_results" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.10.0"

  bucket = "aws-athena-query-results-${local.account_id}"

  attach_deny_insecure_transport_policy = true
}
