module "cms_admin_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.7.0"

  name = "${local.prefix}-cms-admin"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.cms_admin_alb_security_group.security_group_id]

  access_logs = {
    bucket  = data.aws_s3_bucket.elb_logs_eu_west_2.id
    enabled = true
    prefix  = "cms-admin-alb"
  }

  target_groups = [
    {
      name             = "${local.prefix}-cms-admin"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "ip"
      health_check = {
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

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
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

  depends_on = [
    module.s3_logs
  ]
}

module "cms_admin_alb_security_group" {
  source = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"
  
  name   = "${local.prefix}-cms-admin-alb"
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      description = "https from internet"
      rule        = "https-443-tcp"
      cidr_blocks = join(",",
        local.ip_allow_list.engineers,
        local.ip_allow_list.project_team,
        local.ip_allow_list.other_stakeholders,
        local.ip_allow_list.user_testing_participants
      )
    },
    {
      description = "http from internet"
      rule        = "http-80-tcp"
      cidr_blocks = join(",",
        local.ip_allow_list.engineers,
        local.ip_allow_list.project_team,
        local.ip_allow_list.other_stakeholders,
        local.ip_allow_list.user_testing_participants
      )
    }
  ]

  egress_with_source_security_group_id = [
    {
      description              = "lb to tasks"
      rule                     = "http-80-tcp"
      source_security_group_id = module.ecs_service_cms_admin.security_group_id
    }
  ]
}
