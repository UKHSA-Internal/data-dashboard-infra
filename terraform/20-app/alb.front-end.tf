module "front_end_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.10.0"

  name = "${local.prefix}-front-end"

  load_balancer_type = "application"

  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  security_groups            = [module.front_end_alb_security_group.security_group_id]
  drop_invalid_header_fields = true
  enable_deletion_protection = false

  access_logs = {
    bucket  = data.aws_s3_bucket.elb_logs_eu_west_2.id
    enabled = true
    prefix  = "front-end-alb"
  }

  target_groups = {
    "${local.prefix}-front-end-tg" = {
      name              = "${local.prefix}-front-end-tg"
      backend_protocol  = "HTTP"
      backend_port      = 3000
      target_type       = "ip"
      create_attachment = false
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
  }

  listeners = {
    "${local.prefix}-front-end-alb-listener" = {
      name            = "${local.prefix}-front-end-alb-listener"
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = local.certificate_arn
      ssl_policy      = local.alb_security_policy
      fixed_response = {
        content_type = "text/plain"
        message_body = "403 Forbidden"
        status_code  = "403"
      }
      rules = {
        enforce-header-value = {
          listener_key = "${local.prefix}-front-end-alb-listener"
          priority     = 1
          actions      = [
            {
              type             = "forward"
              target_group_key = "${local.prefix}-front-end-tg"
            }
          ]
          conditions = [
            {
              http_header = {
                http_header_name = "x-cdn-auth"
                values           = [
                  jsonencode(aws_secretsmanager_secret_version.cdn_front_end_secure_header_value.secret_string)
                ]
              }
            }
          ]
        }
      }
    }
  }
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
