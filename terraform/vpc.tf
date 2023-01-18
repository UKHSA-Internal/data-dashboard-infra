
resource "aws_subnet" "subnet_1" {
  vpc_id     = var.vpc_id
  cidr_block = "10.14.224.64/27"
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "wp-test-subnet"
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id     = var.vpc_id
  cidr_block = "10.14.224.128/27"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "wp-test-subnet"
  }
}

resource "aws_subnet" "subnet_3" {
  vpc_id     = var.vpc_id
  cidr_block = "10.14.224.96/27"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "wp-test-subnet"
  }
}

resource "aws_security_group_rule" "example" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = var.default_sg
}

resource "aws_route_table_association" "aws_route_table_association_subnet_1" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = var.route_table_id
}

resource "aws_route_table_association" "aws_route_table_association_subnet_2" {
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = var.route_table_id
}

resource "aws_route_table_association" "aws_route_table_association_subnet_3" {
  subnet_id      = aws_subnet.subnet_3.id
  route_table_id = var.route_table_id
}




data "aws_subnets" "app_subnets"{
  filter{
    name = "vpc-id"
    values = [var.vpc_id]
  }
}







