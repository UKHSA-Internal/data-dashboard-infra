module "front_end_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.5.0"

  name = "${local.prefix}-front-end"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.front_end_alb_security_group.security_group_id]

  access_logs = {
    bucket  = data.aws_s3_bucket.elb_logs_eu_west_2.id
    enabled = true
    prefix  = "front-end-alb"
  }

  target_groups = [
    {
      name             = "${local.prefix}-front-end"
      backend_protocol = "HTTP"
      backend_port     = 3000
      target_type      = "ip"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/api/health"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200,404"
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
      action_type        = "fixed-response"
      fixed_response = {
        content_type = "text/plain"
        message_body = "403 Forbidden"
        status_code  = "403"
      }
    }
  ]

  https_listener_rules = [
    {
      https_listener_index = 0
      priority             = 1
      actions = [
        {
          type               = "forward"
          target_group_index = 0
        }
      ]
      conditions = [
        {
          http_headers = [{
            http_header_name = "x-cdn-auth"
            values           = [jsonencode(aws_secretsmanager_secret_version.cdn_front_end_secure_header_value.secret_string)]
          }]
        }
      ]
    }
  ]
}

module "front_end_alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name   = "${local.prefix}-front-end-alb"
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      description = "https from allowed ips"
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_source_security_group_id = [
    {
      description              = "lb to tasks"
      from_port                = 3000
      to_port                  = 3000
      protocol                 = "TCP"
      source_security_group_id = module.ecs_service_front_end.security_group_id
    }
  ]
}
