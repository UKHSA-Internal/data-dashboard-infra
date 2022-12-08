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

  tags = {
    Name = "Main"
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id     = aws_vpc.wp_dev_vpc.id
  cidr_block = "10.10.144.128/27"

  tags = {
    Name = "Main"
  }
}

resource "aws_subnet" "subnet_3" {
  vpc_id     = aws_vpc.wp_dev_vpc.id
  cidr_block = "10.10.144.0/27"

  tags = {
    Name = "Main"
  }
}


resource "aws_db_subnet_group" "default" {
  name        = "main"
  description = "Terraform example RDS subnet group"
  subnet_ids  = [aws_subnet.subnet_1.id,aws_subnet.subnet_2.id,aws_subnet.subnet_3.id]
}




/*


data "aws_subnet" "subnet_1" {
  id = var.subnet_id_1
}

data "aws_subnet" "subnet_2" {
  id = var.subnet_id_2
}

data "aws_subnet" "subnet_3" {
  id = var.subnet_id_3
}

data "aws_subnet" "subnet_4" {
  id = var.subnet_id_4
}

data "aws_subnet" "subnet_5" {
  id = var.subnet_id_5
}

data "aws_subnet" "subnet_6" {
  id = var.subnet_id_6
}

data "aws_subnet" "subnet_7" {
  id = var.subnet_id_7
}

data "aws_subnets" "app_subnets"{
  filter{
    name = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_db_subnet_group" "default" {
  name        = "main1"
  description = "Terraform example RDS subnet group"
  subnet_ids  = [var.subnet_id_1,var.subnet_id_2,var.subnet_id_3,var.subnet_id_4,var.subnet_id_5,var.subnet_id_6,var.subnet_id_7]
}

resource aws_vpc_endpoint "s3_endpoint" {
  vpc_id = var.vpc_id
  service_name = "com.amazonaws.eu-west-2.s3"
  route_table_ids = ["rtb-0cfb03a1ff2c0029c"]
}
*/





