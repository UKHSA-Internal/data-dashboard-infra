module "iam_data_ingestion_automation_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "5.46.0"

  name = "DataIngestionAutomation"

  create_iam_user_login_profile = false
  create_iam_access_key         = false
  policy_arns                   = [module.iam_data_ingestion_automation_policy.arn]
}

module "iam_data_ingestion_automation_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.46.0"

  name = "uhd-data-ingestion-automation-policy"

  policy = jsonencode(
    {
      Version   = "2012-10-17",
      Statement = [
        {
          Action   = ["sts:AssumeRole"],
          Effect   = "Allow",
          Resource = module.iam_operations_role.iam_role_arn
        }
      ]
    }
  )
}
