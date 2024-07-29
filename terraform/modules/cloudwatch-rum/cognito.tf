resource "aws_cognito_identity_pool" "this" {
  identity_pool_name               = var.name
  allow_unauthenticated_identities = true
  allow_classic_flow               = true
}

resource "aws_cognito_identity_pool_roles_attachment" "this" {
  identity_pool_id = aws_cognito_identity_pool.this.id
  roles = {
    "unauthenticated" = aws_iam_role.this.arn
  }
}
