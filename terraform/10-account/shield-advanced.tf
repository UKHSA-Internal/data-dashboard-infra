resource "aws_iam_role_policy_attachment" "shield_advanced_drt" {
  role       = module.shield_advanced_drt_role.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSShieldDRTAccessPolicy"
}

resource "aws_shield_drt_access_role_arn_association" "shield_advanced_drt" {
  role_arn = aws_iam_role.shield_advanced_drt.arn
}