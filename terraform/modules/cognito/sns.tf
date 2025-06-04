module "cognito_sns" {
  source  = "terraform-aws-modules/sns/aws"
  version = "6.1.2"

  name = "${var.prefix}-cognito-topic"
}
