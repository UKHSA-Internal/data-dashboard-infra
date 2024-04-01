module "ecs_service_bastion" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.10.1"

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
      command                                = ["sleep", "infinity"]
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
}

module "bastion_service_security_group_rules" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  create_sg         = false
  security_group_id = module.ecs_service_bastion.security_group_id

  egress_with_cidr_blocks = [
    {
      description = "http to internet"
      rule        = "http-80-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "https to internet"
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

resource "aws_cloudwatch_log_subscription_filter" "ecs_service_bastion" {
  count = local.ship_cloud_watch_logs_to_splunk ? 1 : 0

  destination_arn = local.account_layer.kinesis.cloud_watch_logs_to_splunk.eu_west_2.destination_arn
  filter_pattern  = ""
  log_group_name  = module.ecs_service_bastion.container_definitions["bastion"].cloudwatch_log_group_name
  name            = "splunk"
  role_arn        = local.account_layer.kinesis.cloud_watch_logs_to_splunk.eu_west_2.role_arn
}
