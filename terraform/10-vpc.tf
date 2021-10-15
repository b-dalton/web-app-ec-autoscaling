// Set up VPC in AWS account to house all resources
resource "aws_vpc" "pizza_vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Owner = var.owner
  }
}

// Two subnets each in a different availability zone, improves availability
resource "aws_subnet" "pizza_subnet_a" {
  vpc_id                  = aws_vpc.pizza_vpc.id
  cidr_block              = var.cidr_block_subnet_a
  availability_zone       = var.aws_availability_zone_a
  map_public_ip_on_launch = false

  tags = {
    Owner = var.owner
  }
}

resource "aws_subnet" "pizza_subnet_b" {
  vpc_id                  = aws_vpc.pizza_vpc.id
  cidr_block              = var.cidr_block_subnet_b
  availability_zone       = var.aws_availability_zone_b
  map_public_ip_on_launch = false // toggle to auto assign public ip to instances launched in this subnet

  tags = {
    Owner = var.owner
  }
}

// Allows traffic from outside VPC
resource "aws_internet_gateway" "pizza_gateway" {
  vpc_id = aws_vpc.pizza_vpc.id

  tags = {
    Owner = var.owner
  }
}

// VPC routing table - this was imported from AWS account
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.pizza_vpc.id
}

// Create an association between the route table and each subnet
resource "aws_route_table_association" "public_subnet_assoc_a" {
  subnet_id      = aws_subnet.pizza_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_assoc_b" {
  subnet_id      = aws_subnet.pizza_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

// Create a routing table entry (a route) in a VPC routing table.
resource "aws_route" "pizza_r" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.pizza_gateway.id
  depends_on             = [aws_route_table.public_rt]
}
