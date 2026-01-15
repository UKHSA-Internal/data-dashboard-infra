module "cognito_sns" {
  source  = "terraform-aws-modules/sns/aws"
  version = "7.0.0"

  name = "${var.prefix}-cognito-topic"
}
