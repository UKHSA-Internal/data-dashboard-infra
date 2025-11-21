module "ecs_service_bastion" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "6.9.0"

  name                   = "${local.prefix}-bastion"
  cluster_arn            = module.ecs.cluster_arn
  enable_execute_command = true

  cpu        = 256
  memory     = 512
  subnet_ids = module.vpc.private_subnets

  enable_autoscaling = false
  desired_count      = 0

  runtime_platform = {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }

  container_definitions = {
    bastion = {
      cloudwatch_log_group_retention_in_days = local.default_log_retention_in_days
      command = ["sleep", "infinity"]
      cpu                                    = 256
      essential                              = true
      image                                  = "public.ecr.aws/amazonlinux/amazonlinux:2023"
      memory                                 = 512
      readonly_root_filesystem               = false
    }
  }

  tasks_iam_role_statements = [
    {
      actions = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ]
      resources = ["*"]
    }
  ]

  task_exec_iam_statements = [
    {
      actions = ["kms:Decrypt"]
      resources = [
        module.kms_secrets_app_engineer.key_arn,
        module.kms_app_rds.key_arn,
        module.kms_secrets_app_operator.key_arn,
      ]
    },
    {
      actions = ["secretsmanager:GetSecretValue"]
      resources = [
        local.main_db_aurora_password_secret_arn,
        aws_secretsmanager_secret.backend_cryptographic_signing_key.arn
      ]
    }
  ]

  security_group_egress_rules = {
    internet_https = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "https to internet"
      cidr_ipv4   = "0.0.0.0/0"
    }
    internet_http = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "http to internet"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
}
