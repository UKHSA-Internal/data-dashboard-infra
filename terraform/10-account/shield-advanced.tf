resource "aws_iam_role" "shield_advanced_drt" {
  name               = "ShieldAdvancedDRTRole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "drt.shield.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "shield_advanced_drt" {
  role       = aws_iam_role.shield_advanced_drt.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSShieldDRTAccessPolicy"
}

resource "aws_shield_drt_access_role_arn_association" "shield_advanced_drt" {
  role_arn = aws_iam_role.shield_advanced_drt.arn
}