#resource "aws_alb" "wp_application_load_balancer" {
#  name               = "wp-lb" # Naming our load balancer
#  load_balancer_type = "application"
#  subnets = [var.subnet_id_1,var.subnet_id_2,var.subnet_id_3]
#  # Referencing the security group
#  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
#}
#
## Creating a security group for the load balancer:
#resource "aws_security_group" "load_balancer_security_group" {
#  ingress {
#    from_port   = 80 # Allowing traffic in from port 80
#    to_port     = 80
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
#  }
#
#  egress {
#    from_port   = 0 # Allowing any incoming port
#    to_port     = 0 # Allowing any outgoing port
#    protocol    = "-1" # Allowing any outgoing protocol 
#    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
#  }
#}