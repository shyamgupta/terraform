terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.40.0"
    }
  }
}

provider "aws" {
  # Configuration options
	region = "us-east-1"
    
    # Create VPC
    resource "aws_vpc" "my_vpc"{
        cidr_block = "10.0.0.0/8"
    }
    
    # Create Public Subnets
    resource "aws_subnet" "pub-subnet-1"{
        vpc_id = aws_vpc.my_vpc.id
        cidr_block = "10.0.1.0/16"
    }
    resource "aws_subnet" "pub-subnet-2"{
        vpc_id = aws_vpc.my_vpc.id
        cidr_block = "10.0.2.0/16"
    }

    # Create Private Subnets
    resource "aws_subnet" "pri-subnet-1"{
        vpc_id = aws_vpc.my_vpc.id
        cidr_block = "10.0.3.0/16"
    }
    resource "aws_subnet" "pri-subnet-2"{
        vpc_id = aws_vpc.my_vpc.id
        cidr_block = "10.0.4.0/16"
    }
    
    # Create Internet Gateway
    resource "aws_internet_gateway" "igw"{
        vpc_id = aws_vpc.my_vpc.id
    }

    # Create an Elastic IP for NAT Gateway
    resource "aws_eip" "eip"{
        vpc = true
    } 

    # Create NAT Gateway
    resource "aws_nat_gateway" "ngw"{
        allocation_id = aws_eip.eip.id
        subnet_id = aws_subnet.pri-subnet-1.id
        depends_on = [aws_internet_gateway.igw]
    }
    
    # Create Route Tables
    resource "aws_route_table" "public_route_table"{
        vpc_id = aws_vpc.my_vpc.id
        route{
            cidr_block = "0.0.0.0/0"
            gateway_id = aws_internet_gateway.igw
        }
    }
    
    route "aws_route_table_association" "public1"{
        subnet_id = aws_subnet.pub-subnet-1.id
        route_table_id = aws_route_table.public_route_table.id
    }
    
    route "aws_route_table_association" "public2"{
        subnet_id = aws_subnet.pub-subnet-2.id
        route_table_id = aws_route_table.public_route_table.id
    }
    
    resource "aws_route_table" "private_route_table"{
        vpc_id = aws_vpc.my_vpc.id
        route{
            cidr_block = "0.0.0.0/0"
            nat_gateway_id = aws_nat_gateway.ngw.id
        }
    }
    resource "aws_route_table_association" "private1"{
        subnet_id = aws_subnet.pri-subnet-1.id
        route_table_id = aws_route_table.private_route_table.id
    }
    
    resource "aws_route_table_association" "private2"{
        subnet_id = aws_subnet.pri-subnet-2.id
        route_table_id = aws_route_table.private_route_table.id
    }
}   

