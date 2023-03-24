 # IAM roles
resource "aws_iam_role" "app_execution_role" {
  name               = "${var.project_name}-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ecs.amazonaws.com",
          "ecs-tasks.amazonaws.com"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role" "api_role" {
  name = "devops_github_actions_wp_api"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::518944279943:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:publichealthengland/winter-pressures-api:*"
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_policy" "policy" {
  name        = "devops_github_actions_wp_api_policy"
  description = "A test policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "rds:*",
        "ecr:*",
        "ec2:*",
        "ecs:*",
        "secretsmanager:ListSecretVersionIds",
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"

      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "frontend_role" {
  name = "devops_github_actions_wp_frontend"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::518944279943:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:publichealthengland/winter-pressures-frontend:*"
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_policy" "frontend_policy" {
  name        = "devops_github_actions_wp_frontend_policy"
  description = "A test policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "rds:*",
        "ecr:*",
        "ec2:*",
        "ecs:*" 
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "api_attach" {
  role       = aws_iam_role.api_role.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_role_policy_attachment" "frontend_attach" {
  role       = aws_iam_role.frontend_role.name
  policy_arn = aws_iam_policy.frontend_policy.arn
}
