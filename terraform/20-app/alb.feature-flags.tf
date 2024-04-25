module "feature_flags_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.9.0"

  name = "${local.prefix}-feature-flags"

  load_balancer_type = "application"

  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  security_groups            = [module.feature_flags_alb_security_group.security_group_id]
  drop_invalid_header_fields = true

  access_logs = {
    bucket  = data.aws_s3_bucket.elb_logs_eu_west_2.id
    enabled = true
    prefix  = "feature-flags-alb"
  }

  target_groups = [
    {
      name             = "${local.prefix}-feature-flags"
      backend_protocol = "HTTP"
      backend_port     = 4242
      target_type      = "ip"
      health_check     = {
        enabled             = true
        interval            = 30
        path                = "/health/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = local.certificate_arn
      target_group_index = 0
      ssl_policy         = local.alb_security_policy
    }
  ]
}

module "feature_flags_alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name   = "${local.prefix}-feature-flags-alb"
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      description = "https from internet"
      rule        = "https-443-tcp"
      cidr_blocks = join(",",
        local.ip_allow_list.engineers,
        local.ip_allow_list.project_team,
        local.ip_allow_list.other_stakeholders
      )
    }
  ]

  egress_with_source_security_group_id = [
    {
      description              = "lb to tasks"
      from_port                = 4242
      to_port                  = 4242
      protocol                 = "tcp"
      source_security_group_id = module.ecs_service_feature_flags.security_group_id
    }
  ]
}
