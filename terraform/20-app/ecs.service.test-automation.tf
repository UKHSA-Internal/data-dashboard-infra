module "ecs_service_test_automation" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.11.4"

  name                   = "${local.prefix}-test-automation"
  cluster_arn            = module.ecs.cluster_arn
  enable_execute_command = true

  cpu        = 256
  memory     = 512
  subnet_ids = module.vpc.private_subnets

  enable_autoscaling = false
  desired_count      = 1

  autoscaling_scheduled_actions = local.use_prod_sizing ? {} : local.scheduled_scaling_policies_for_non_essential_envs

  runtime_platform = {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }

  container_definitions = {
    bridge-client = {
      cpu                                    = 256
      memory                                 = 512
      essential                              = true
      readonly_root_filesystem               = false
      image                                  = "${module.ecr_test_automation.repository_url}:latest"
      port_mappings = [
        {
          containerPort = 443
          hostPort      = 443
          protocol      = "tcp"
        }
      ]
      secrets = [
        {
          name      = "TOKEN",
          valueFrom = "${aws_secretsmanager_secret.virtuoso_token.arn}:token::"
        }
      ]
    }
  }

  security_group_rules = {
    # egress rules
    internet_egress = {
      type        = "egress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "https to internet"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
