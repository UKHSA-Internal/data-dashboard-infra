module "shield_advanced_drt_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.37.1"

  create_role          = true
  max_session_duration = 43200
  role_name            = "ShieldAdvancedDRTRole"
  role_requires_mfa    = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSShieldDRTAccessPolicy",
    module.iam_shield_advanced_drt_policy.arn,
  ]
}

module "iam_shield_advanced_drt_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.37.1"

  name = "uhd-shield-advanced-drt-policy"

  policy = jsonencode(
    {
      Version   = "2012-10-17",
      Statement = [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "drt.shield.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        },
      ]
    }
  )
}
