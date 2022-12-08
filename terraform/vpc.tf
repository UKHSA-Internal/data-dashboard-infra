resource "aws_vpc" "wp_dev_vpc" {
  cidr_block       = "10.10.144.0/20"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "subnet_1" {
  vpc_id     = aws_vpc.wp_dev_vpc.id
  cidr_block = "10.10.144.64/27"
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "wp-dev-subnet"
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id     = aws_vpc.wp_dev_vpc.id
  cidr_block = "10.10.144.128/27"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "wp-dev-subnet"
  }
}

resource "aws_subnet" "subnet_3" {
  vpc_id     = aws_vpc.wp_dev_vpc.id
  cidr_block = "10.10.144.0/27"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "wp-dev-subnet"
  }
}


resource "aws_db_subnet_group" "default" {
  name        = "main"
  description = "Terraform example RDS subnet group"
  subnet_ids  = [aws_subnet.subnet_1.id,aws_subnet.subnet_2.id,aws_subnet.subnet_3.id]
}


data "aws_subnets" "app_subnets"{
  filter{
    name = "vpc-id"
    values = [aws_vpc.wp_dev_vpc]
  }
}







