provider "aws" {}

# Variables for reusability and flexibility
variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}

# Creating a custom VPC with a name based on the environment prefix
resource "aws_vpc" "myapp-vpc" {
    cidr_block  = var.vpc_cidr_block
    tags = {
        Name = "${var.env_prefix}-vpc"
    }
}

# Creating a subnet in the specified Availability Zone within the custom VPC
resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name = "${var.env_prefix}-subnet-1"
    }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {
    Name = "${var.env_prefix}-igw"
  }
}

resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

 tags = {
    Name = "${var.env_prefix}-main-rtb"
  }

}

