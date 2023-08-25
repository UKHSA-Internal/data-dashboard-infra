data "aws_iam_roles" "administrator" {
  name_regex  = "AWSReservedSSO_Administrator_*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "developer" {
  name_regex  = "AWSReservedSSO_Developer_*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

locals {
  sso_role_arns = {
    administrator = tolist(data.aws_iam_roles.administrator.arns)[0]
    developer     = tolist(data.aws_iam_roles.developer.arns)[0]
  }
}
