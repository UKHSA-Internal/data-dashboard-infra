 # IAM roles
resource "aws_iam_role" "app_execution_role" {
  name               = "${var.project_name}-execution-role-1"
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

resource "aws_iam_role" "role" {
  name = "devops_github_actions_wp_api"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::574290571051:oidc-provider/token.actions.githubusercontent.com"
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
        "ecr:*"

      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

data "aws_iam_role" "devops_github_actions" {
  name = "devops_github_actions"
}

resource "aws_iam_policy" "devops_github_actions_policy" {
  name        = "devops_github_actions_33"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "s3:*",
                "secretsmanager:ListSecretVersionIds",
                "rds:*",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "iam:AttachRolePolicy",
                "iam:CreateRole",
                "iam:GetRole",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "iam:CreatePolicy",
                "iam:ListInstanceProfilesForRole",
                "iam:GetPolicy",
                "iam:DeleteRole",
                "iam:GetPolicyVersion",
                "iam:ListPolicyVersions",
                "iam:DeletePolicy",
                "iam:DetachRolePolicy",
                "iam:PassRole",
                "iam:CreatePolicyVersion",
                "ecs:RegisterTaskDefinition"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "devops_github_actions_attach" {
  role       = data.aws_iam_role.devops_github_actions.id
  policy_arn = aws_iam_policy.devops_github_actions_policy.arn
}