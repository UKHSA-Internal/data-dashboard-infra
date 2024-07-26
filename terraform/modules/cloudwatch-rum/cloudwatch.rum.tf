resource "aws_rum_app_monitor" "this" {
  name   = var.name
  domain = var.domain_name

  app_monitor_configuration {
    session_sample_rate = var.session_sample_rate

    identity_pool_id = aws_cognito_identity_pool.this.id
    guest_role_arn   = aws_iam_role.this.arn
  }
}
