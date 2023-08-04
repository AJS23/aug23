terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-west-1"
}

# Create a VPC
resource "aws_vpc" "EKS-VPC" {
  cidr_block = "10.0.0.0/16"
 
tags = {
    Name = "EKS-VPC"
  }
}

# connecting subnet to vpc 
resource "aws_subnet" "EKS-SUBNET-PUBLIC" {
  vpc_id     = aws_vpc.EKS-VPC.id
  cidr_block = "10.0.0.0/20"
  availability_zone = "us-west-1a" 
  map_public_ip_on_launch = "true"

  tags = {
    Name = "EKS-SUBNET-PUBLIC"
  }
}

resource "aws_subnet" "EKS-SUBNET-PUBLIC-2" {
  vpc_id     = aws_vpc.EKS-VPC.id
  cidr_block = "10.0.16.0/20"
  availability_zone = "us-west-1b"
   map_public_ip_on_launch = "true"

  tags = {
    Name = "EKS-SUBNET-PUBLIC-2"
  }
}
#connecting internet gateway
resource "aws_internet_gateway" "EKS-IGW" {
  vpc_id = aws_vpc.EKS-VPC.id

  tags = {
    Name = "EKS-IGW"
  }
}
#route table association
resource "aws_route_table" "EKS-ROUTE" {
  vpc_id = aws_vpc.EKS-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.EKS-IGW.id
  }
   
  tags = {
    Name = "EKS-ROUTE"
  }
}
#subnet association
resource "aws_route_table_association" "EKS-ROUTE-ASSOCIATION" {
  subnet_id      = aws_subnet.EKS-SUBNET-PUBLIC.id
  route_table_id = aws_route_table.EKS-ROUTE.id
}
resource "aws_route_table_association" "EKS-ROUTE-ASSOCIATION1" {
  subnet_id      = aws_subnet.EKS-SUBNET-PUBLIC-2.id
  route_table_id = aws_route_table.EKS-ROUTE.id
}
#security group creation
resource "aws_security_group" "EKS-SECURITY" {
  name        = "EKS-SECURITY"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.EKS-VPC.id

  ingress {
    description      = "SECURITY GROUP"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "EKS-SECURITY"
  }
}

#ec2 creation
resource "aws_instance" "FROM-EKS-TERRA" {
  ami                     = "ami-0f8e81a3da6e2510a"
  instance_type           = "t2.medium"
  key_name                = "northcalifornia"
  vpc_security_group_ids  = [aws_security_group.EKS-SECURITY.id]
  subnet_id               = aws_subnet.EKS-SUBNET-PUBLIC.id
tags = {
    Name = "FROM-EKS-TERRA"
  }
}
