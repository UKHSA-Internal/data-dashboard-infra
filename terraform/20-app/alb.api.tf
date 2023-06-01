module "api_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.6.0"

  name = "${local.prefix}-api"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.api_alb_security_group.security_group_id]

  target_groups = [
    {
      name             = "${local.prefix}-api"
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
}

module "api_alb_security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "${local.prefix}-api-alb"
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      description = "http from internet"
      rule        = "http-80-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_source_security_group_id = [
    {
      description              = "lb to tasks"
      rule                     = "http-80-tcp"
      source_security_group_id = module.ecs_service_api.security_group_id
    }
  ]
}
