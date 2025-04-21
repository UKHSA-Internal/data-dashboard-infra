module "feature_flags_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.16.0"

  name = "${local.prefix}-feature-flags"

  load_balancer_type = "application"

  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  drop_invalid_header_fields = true
  enable_deletion_protection = false

  access_logs = {
    bucket  = data.aws_s3_bucket.elb_logs_eu_west_2.id
    enabled = true
    prefix  = "feature-flags-alb"
  }

  target_groups = {
    "${local.prefix}-feature-flags" = {
      name              = "${local.prefix}-feature-flags"
      backend_protocol  = "HTTP"
      backend_port      = 4242
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
    "${local.prefix}-feature-flags-alb-listener" = {
      name            = "${local.prefix}-feature-flags-alb-listener"
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
          listener_key = "${local.prefix}-feature-flags-alb-listener"
          priority     = 1
          actions      = [
            {
              type             = "forward"
              target_group_key = "${local.prefix}-feature-flags"
            }
          ]
          conditions = [
            {
              http_header = {
                http_header_name = "x-auth"
                values           = [
                  jsondecode(aws_secretsmanager_secret_version.feature_flags_api_keys.secret_string)["x_auth"]
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
      from_port                    = 4242
      to_port                      = 4242
      referenced_security_group_id = module.ecs_service_feature_flags.security_group_id
    }
  }
}
