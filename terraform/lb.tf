resource "aws_alb" "wp_application_load_balancer" {
  name               = "wp-lb-1" # Naming our load balancer
  load_balancer_type = "application"
  subnets = [var.subnet_id_1,var.subnet_id_2,var.subnet_id_3]
  # Referencing the security group
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}

resource "aws_alb" "wp_application_load_balancer_api" {
  name               = "wp-lb-api" # Naming our load balancer
  load_balancer_type = "application"
  subnets = [var.subnet_id_5,var.subnet_id_6,var.subnet_id_7]
  # Referencing the security group
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}
# Creating a security group for the load balancer:
resource "aws_security_group" "load_balancer_security_group" {
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 443 # Allowing traffic in from port 80
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
  }

  egress {
    from_port   = 0 # Allowing any incoming port
    to_port     = 0 # Allowing any outgoing port
    protocol    = "-1" # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}

resource "aws_lb_target_group" "wp_target_group" {
  name        = "wp-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id # Referencing the default VPC
  health_check {
    matcher = "200-400"
    path = "/"
    interval = 70
  }
}

resource "aws_lb_target_group" "wp_api_target_group" {
  name        = "wp-api-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id # Referencing the default VPC
  health_check {
    matcher = "200-400"
    path = "/"
    interval = 70
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_alb.wp_application_load_balancer.arn}" # Referencing our load balancer
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.wp_target_group.arn}" # Referencing our tagrte group
  }
}

resource "aws_lb_listener" "api_listener" {
  load_balancer_arn = "${aws_alb.wp_application_load_balancer_api.arn}" # Referencing our load balancer
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.wp_api_target_group.arn}" # Referencing our tagrte group
  }
}