
resource "aws_subnet" "subnet_1" {
  vpc_id     = var.vpc_id
  cidr_block = "10.14.208.64/27"
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "wp-dev-subnet"
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id     = var.vpc_id
  cidr_block = "10.14.208.128/27"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "wp-dev-subnet"
  }
}

resource "aws_subnet" "subnet_3" {
  vpc_id     = var.vpc_id
  cidr_block = "10.14.208.96/27"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "wp-dev-subnet"
  }
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







