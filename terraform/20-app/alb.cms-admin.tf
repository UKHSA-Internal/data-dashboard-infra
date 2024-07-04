module "cms_admin_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.9.0"

  name = "${local.prefix}-cms-admin"

  load_balancer_type = "application"

  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  security_groups            = [module.cms_admin_alb_security_group.security_group_id]
  drop_invalid_header_fields = true
  enable_deletion_protection = false

  access_logs = {
    bucket  = data.aws_s3_bucket.elb_logs_eu_west_2.id
    enabled = true
    prefix  = "cms-admin-alb"
  }

  target_groups = {
    "${local.prefix}-cms-admin-tg" = {
      name              = "${local.prefix}-cms-admin-tg"
      backend_protocol  = "HTTP"
      backend_port      = 80
      target_type       = "ip"
      create_attachment = false
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
  }

  listeners = {
    "${local.prefix}-cms-admin-alb-listener" = {
      name               = "${local.prefix}-cms-admin-alb-listener"
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = local.certificate_arn
      target_group_index = 0
      ssl_policy         = local.alb_security_policy
      forward = {
        target_group_key = "${local.prefix}-cms-admin-tg"
      }
    }
  }
}

module "cms_admin_alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name   = "${local.prefix}-cms-admin-alb"
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      description = "https from internet"
      rule        = "https-443-tcp"
      cidr_blocks = join(",", local.complete_ip_allow_list)
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
