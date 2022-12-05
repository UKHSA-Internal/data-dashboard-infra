

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

resource "aws_internet_gateway" "s3_gateway" {
  vpc_id = var.vpc_id
}

resource aws_route_table "s3_route_table" {
  vpc_id = var.vpc_id
}

resource aws_route "s3_route" {
  route_table_id = aws_route_table.s3_route_table
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.s3_gateway
}

resource aws_route_table_association "s3_route_table_association_1" {
  subnet_id = data.aws_subnet.subnet_1
  route_table_id = aws_route_table.s3_route_table
}

resource aws_route_table_association "s3_route_table_association_2" {
  subnet_id = data.aws_subnet.subnet_2
  route_table_id = aws_route_table.s3_route_table
}

resource aws_route_table_association "s3_route_table_association_3" {
  subnet_id = data.aws_subnet.subnet_3
  route_table_id = aws_route_table.s3_route_table
}

resource aws_route_table_association "s3_route_table_association_4" {
  subnet_id = data.aws_subnet.subnet_4
  route_table_id = aws_route_table.s3_route_table
}

resource aws_route_table_association "s3_route_table_association_5" {
  subnet_id = data.aws_subnet.subnet_5
  route_table_id = aws_route_table.s3_route_table
}

resource aws_route_table_association "s3_route_table_association_6" {
  subnet_id = data.aws_subnet.subnet_6
  route_table_id = aws_route_table.s3_route_table
}

resource aws_route_table_association "s3_route_table_association_7" {
  subnet_id = data.aws_subnet.subnet_7
  route_table_id = aws_route_table.s3_route_table
}

resource aws_vpc_endpoint "s3_endpoint" {
  vpc_id = var.vpc_id
  service_name = "com.amazonaws.eu-west2.s3"
}

resource aws_vpc_endpoint_route_table_association "s3_endpoint_route_table_association" {
  route_table_id = aws_route_table.s3_route_table
  vpc_endpoint_id = aws_vpc_endpoint.s3_endpoint
}
