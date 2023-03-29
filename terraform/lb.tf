resource "aws_alb" "wp_application_load_balancer_ui" {
  name               = var.lb_ui_name # Naming our load balancer
  load_balancer_type = var.lb_type 
  subnets = [aws_subnet.subnet_1.id,aws_subnet.subnet_2.id,aws_subnet.subnet_3.id]
  # Referencing the security group
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}


resource "aws_alb" "wp_application_load_balancer_api" {
  name               = var.lb_api_name # Naming our load balancer
  load_balancer_type = var.lb_type 
  subnets = [aws_subnet.subnet_1.id,aws_subnet.subnet_2.id,aws_subnet.subnet_3.id]
  # Referencing the security group
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}



# Creating a security group for the load balancer:
resource "aws_security_group" "load_balancer_security_group" {
  vpc_id      = var.vpc_id
  ingress {
    from_port   = var.ingress1_port  # Allowing traffic in from port 80
    to_port     = var.ingress1_port
    protocol    = var.ingress_protocal
    cidr_blocks = var.ingress1_cidr 
  }

  ingress {
    from_port   = var.ingress1_port # Allowing traffic in from port 80
    to_port     = var.ingress1_port
    protocol    = var.ingress_protocal
    cidr_blocks = var.ingress2_cidr # Allowing traffic in from all sources
    security_groups  = var.allowed_sg_list
  }

  ingress {
    from_port   = var.ingress2_port # Allowing traffic in from port 443
    to_port     = var.ingress2_port
    protocol    = var.ingress_protocal
    cidr_blocks = var.ingress2_cidr # Allowing traffic in from all sources
    security_groups  = var.allowed_sg_list
  }
  
  
  egress {
    from_port   = var.egress_port # Allowing any incoming port
    to_port     = var.egress_port # Allowing any outgoing port
    protocol    = var.egress_protocal # Allowing any outgoing protocol 
    cidr_blocks = var.egress_cidr # Allowing traffic out to all IP addresses
  }
}

# Created UI target group
resource "aws_lb_target_group" "wp_ui_target_group" {
  name        = var.ui_target_group
  port        = var.ui_targetgroup_port
  protocol    = var.ui_targetgroup_protocol
  target_type = var.ui_targetgroup_type
  vpc_id      = var.vpc_id # Referencing the default VPC
  health_check {
    matcher = var.ui_healthcheck_matcher
    path = var.ui_healthcheck_path
    interval = var.ui_healthcheck_interval
  }
}


# Created API target group
resource "aws_lb_target_group" "wp_api_target_group" {
  name        = var.api_target_group
  port        = var.api_targetgroup_port
  protocol    = var.api_targetgroup_protocol
  target_type = var.api_targetgroup_type
  vpc_id      = var.vpc_id # Referencing the default VPC
  health_check {
    matcher = var.api_healthcheck_matcher
    path = var.api_healthcheck_path
    interval = var.api_healthcheck_interval
  }
}


# Created UI LB listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_alb.wp_application_load_balancer_ui.arn}" # Referencing UI load balancer
  port              = var.ui_lb_listener_port
  protocol          = var.ui_lb_listener_protocol

  default_action {
    type             = var.ui_lb_listener_type
    target_group_arn = "${aws_lb_target_group.wp_ui_target_group.arn}" # Referencing UI target group
  }
}


# Created API LB listener
resource "aws_lb_listener" "api_listener" {
  load_balancer_arn = "${aws_alb.wp_application_load_balancer_api.arn}" # Referencing API load balancer
  port              = var.api_lb_listener_port
  protocol          = var.api_lb_listener_protocol

  default_action {
    type             = var.api_lb_listener_type
    target_group_arn = "${aws_lb_target_group.wp_api_target_group.arn}" # Referencing API tagrte group
  }
}

