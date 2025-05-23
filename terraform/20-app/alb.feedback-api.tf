module "feedback_api_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.9.0"

  name = "${local.prefix}-feedback-api"

  load_balancer_type = "application"
  internal           = true

  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  drop_invalid_header_fields = true
  enable_deletion_protection = false

  access_logs = {
    bucket  = data.aws_s3_bucket.elb_logs_eu_west_2.id
    enabled = true
    prefix  = "feedback-api-alb"
  }

  target_groups = {
    "${local.prefix}-feedback-api" = {
      name              = "${local.prefix}-feedback-api"
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
    "${local.prefix}-feedback-api-alb-listener" = {
      name            = "${local.prefix}-feedback-api-alb-listener"
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = local.certificate_arn
      ssl_policy      = local.alb_security_policy
      fixed_response = {
        content_type = "application/json"
        message_body = jsonencode({
          message = "Authentication credentials were not provided."
        })
        status_code = "401"
      }
      rules = {
        enforce-api-key = {
          listener_key = "${local.prefix}-feedback-api-alb-listener"
          priority     = 1
          actions      = [
            {
              type             = "forward"
              target_group_key = "${local.prefix}-feedback-api"
            }
          ]
          conditions = [
            {
              http_header = {
                http_header_name = "Authorization"
                values           = [aws_secretsmanager_secret_version.private_api_key.secret_string]
              }
            }
          ]
        }
      }
    }
  }

  security_group_ingress_rules = {
    ingress_from_front_end = {
      from_port                    = 443
      to_port                      = 443
      ip_protocol                  = "tcp"
      referenced_security_group_id = module.ecs_service_front_end.security_group_id
    }
  }
  security_group_egress_rules = {
    egress_to_tasks = {
      ip_protocol                  = "tcp"
      from_port                    = 80
      to_port                      = 80
      referenced_security_group_id = module.ecs_service_feedback_api.security_group_id
    }
  }
}
