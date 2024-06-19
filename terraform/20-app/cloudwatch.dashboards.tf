resource "aws_cloudwatch_dashboard" "data_ingestion_dashboard" {
  dashboard_name = "${local.prefix}-data-ingestion-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", module.lambda_ingestion.lambda_function_name],
            ["AWS/Lambda", "Errors", "FunctionName", module.lambda_ingestion.lambda_function_name],
          ]
          period    = 60
          stat      = "Average"
          region    = local.region
          live_data = false
          title     = "Invocations / errors"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", module.lambda_ingestion.lambda_function_name],
          ]
          period    = 60
          stat      = "Average"
          region    = local.region
          live_data = false
          title     = "Ingestion lambda duration"
        }
      }
    ]
  })
}