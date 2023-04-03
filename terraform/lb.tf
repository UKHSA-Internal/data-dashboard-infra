resource "aws_alb" "wp_application_load_balancer" {
  name               = "wp-lb-frontend" # Naming our load balancer
  load_balancer_type = "application"
  subnets = [aws_subnet.subnet_1.id,aws_subnet.subnet_2.id,aws_subnet.subnet_3.id]
  # Referencing the security group
  security_groups = aws_security_group.load_balancer_security_group
}


resource "aws_alb" "wp_application_load_balancer_api" {
  name               = "wp-lb-api" # Naming our load balancer
  load_balancer_type = "application"
  subnets = [aws_subnet.subnet_1.id,aws_subnet.subnet_2.id,aws_subnet.subnet_3.id]
  # Referencing the security group
  security_groups = aws_security_group.api_load_balancer_security_group
}

resource "aws_lb_target_group" "wp_target_group" {
  name        = "wp-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id # Referencing the default VPC
  health_check {
    matcher = "200,301,302"
    path = "/"
    interval = 70
  }
}

# Creating a security group for the load balancer:
resource "aws_security_group" "load_balancer_security_group" {
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 80 # Allowing traffic in from port 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["82.16.94.117/32","5.71.224.176/32","81.141.183.138/32","81.187.210.205/32","137.22.182.58/32","62.253.228.2/32","94.192.79.9/32","90.209.237.170/32","152.37.86.22/32","90.193.92.24/32","90.243.49.40/32","147.12.250.190/32","90.193.92.24/32","90.195.40.222/32"]
  }

  ingress {
    from_port   = 80 # Allowing traffic in from port 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [] # Allowing traffic in from all sources
    security_groups  = ["sg-05032a61e7b440e1b"]
  }

  ingress {
    from_port   = 443 # Allowing traffic in from port 80
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [] # Allowing traffic in from all sources
    security_groups  = ["sg-05032a61e7b440e1b"]
  }


  egress {
    from_port   = 0 # Allowing any incoming port
    to_port     = 0 # Allowing any outgoing port
    protocol    = "-1" # Allowing any outgoing protocol
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}


resource "aws_lb_target_group" "wp_api_target_group" {
  name        = "wp-api-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id # Referencing the default VPC
  health_check {
    matcher = "200,301,302"
    path = "/health/"
    interval = 70
  }
}

# Creating a security group for the load balancer:
resource "aws_security_group" "api_load_balancer_security_group" {
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 80 # Allowing traffic in from port 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80 # Allowing traffic in from port 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [] # Allowing traffic in from all sources
    security_groups  = ["sg-05032a61e7b440e1b"]
  }

  ingress {
    from_port   = 443 # Allowing traffic in from port 80
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [] # Allowing traffic in from all sources
    security_groups  = ["sg-05032a61e7b440e1b"]
  }


  egress {
    from_port   = 0 # Allowing any incoming port
    to_port     = 0 # Allowing any outgoing port
    protocol    = "-1" # Allowing any outgoing protocol
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_alb.wp_application_load_balancer.arn}" # Referencing our load balancer
  port              = "3000"
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
    target_group_arn = "${aws_lb_target_group.wp_api_target_group.arn}" # Referencing our target group
  }
}

