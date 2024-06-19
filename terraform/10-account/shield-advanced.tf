resource "aws_iam_role_policy_attachment" "shield_advanced_drt" {
  role       = module.shield_advanced_drt_role.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSShieldDRTAccessPolicy"
}

resource "aws_shield_drt_access_role_arn_association" "shield_advanced_drt" {
  role_arn = module.shield_advanced_drt_role.iam_role_arn
}

resource "aws_shield_drt_access_log_bucket_association" "shield_advanced_drt" {
  log_bucket              = "aws-waf-logs-halo-${local.account_id}-eu-west-2-wpr-${var.halo_account_type}-avm-bs-gr-r"
  role_arn_association_id = aws_shield_drt_access_role_arn_association.shield_advanced_drt.id
}
