resource "aws_cur_report_definition" "green_ops_cur_export" {
  count = local.ship_cur_to_green_ops_dashboard ? 1 : 0

  additional_schema_elements = ["RESOURCES", "SPLIT_COST_ALLOCATION_DATA"]
  compression                = "Parquet"
  format                     = "Parquet"
  report_name                = "data-dashboard-${local.account}"
  report_versioning          = "OVERWRITE_REPORT"
  s3_bucket                  = module.s3_cur_exports.s3_bucket_id
  s3_prefix                  = "cur"
  s3_region                  = local.region
  time_unit                  = "HOURLY"

  provider = aws.us_east_1
}
