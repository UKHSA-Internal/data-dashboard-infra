module "front_end_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "10.0.0"

  name = "${local.prefix}-front-end"

  load_balancer_type = "application"

  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  drop_invalid_header_fields = true
  enable_deletion_protection = false

  access_logs = {
    bucket  = data.aws_s3_bucket.elb_logs_eu_west_2.id
    enabled = true
    prefix  = "front-end-alb"
  }

  target_groups = {
    "${local.prefix}-front-end" = {
      name              = "${local.prefix}-front-end"
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
              target_group_key = "${local.prefix}-front-end"
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

  security_group_ingress_rules = {
    ingress_from_internet = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    egress_to_tasks = {
      ip_protocol                  = "tcp"
      from_port                    = 3000
      to_port                      = 3000
      referenced_security_group_id = module.ecs_service_front_end.security_group_id
    }
  }
}
