module "public_api_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.9.0"

  name = "${local.prefix}-public-api"

  load_balancer_type = "application"

  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  security_groups            = [module.public_api_alb_security_group.security_group_id]
  drop_invalid_header_fields = true
  enable_deletion_protection = false

  access_logs = {
    bucket  = data.aws_s3_bucket.elb_logs_eu_west_2.id
    enabled = true
    prefix  = "public-api-alb"
  }

  target_groups = {
    "${local.prefix}-public-api-tg" = {
      name              = "${local.prefix}-public-api-tg"
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
    "${local.prefix}-public-api-alb-listener" = {
      name            = "${local.prefix}-public-api-alb-listener"
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
          listener_key = "${local.prefix}-public-api-alb-listener"
          priority     = 1
          actions      = [
            {
              type             = "forward"
              target_group_key = "${local.prefix}-public-api-tg"
            }
          ]
          conditions = [
            {
              http_header = {
                http_header_name = "x-cdn-auth"
                values           = [
                  jsonencode(aws_secretsmanager_secret_version.cdn_public_api_secure_header_value.secret_string)
                ]
              }
            }
          ]
        }
      }
    }
  }
}

module "public_api_alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name   = "${local.prefix}-public-api-alb"
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      description = "https from internet"
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_source_security_group_id = [
    {
      description              = "lb to tasks"
      rule                     = "http-80-tcp"
      source_security_group_id = module.ecs_service_public_api.security_group_id
    }
  ]
}
