data "aws_iam_roles" "administrator" {
  name_regex  = "AWSReservedSSO_Administrator_*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "developer" {
  name_regex  = "AWSReservedSSO_Developer_*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "operations" {
  name_regex  = "AWSReservedSSO_Operations_*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "report_viewer" {
  name_regex  = "AWSReservedSSO_ReportViewer_*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

locals {
  sso_role_arns = {
    administrator = one(data.aws_iam_roles.administrator.arns)
    developer     = one(data.aws_iam_roles.developer.arns)
    operations    = one(data.aws_iam_roles.operations.arns)
    report_viewer = one(data.aws_iam_roles.report_viewer.arns)
  }
}
