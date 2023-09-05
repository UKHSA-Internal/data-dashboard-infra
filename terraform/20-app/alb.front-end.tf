module "front_end_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.7.0"

  name = "${local.prefix}-front-end"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.front_end_alb_security_group.security_group_id]

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

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  http_tcp_listener_rules = [
    {
      http_tcp_listener_index = 0
      priority                = 1
      actions                 = [
        {
          type                = "forward"
          target_group_index  = 0
        }
      ]
      conditions = [
        {
          http_headers = [{
            http_header_name  = "x-cdn-auth"
            values            = [jsonencode(aws_secretsmanager_secret_version.cdn_front_end_secure_header_value.secret_string)]
          }]
        }
      ]
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = local.certificate_arn
      target_group_index = 0
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
      description = "http from allowed ips"
      rule        = "http-80-tcp"
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
