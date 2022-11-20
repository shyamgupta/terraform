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
    
}   

    # Create VPC
    resource "aws_vpc" "my_vpc"{
        cidr_block = "10.0.0.0/16"
    }
    
    # Create Public Subnets
    resource "aws_subnet" "pub-subnet-1"{
        vpc_id = aws_vpc.my_vpc.id
        cidr_block = "10.0.1.0/24"
    }
    resource "aws_subnet" "pub-subnet-2"{
        vpc_id = aws_vpc.my_vpc.id
        cidr_block = "10.0.2.0/24"
    }

    # Create Private Subnets
    resource "aws_subnet" "pri-subnet-1"{
        vpc_id = aws_vpc.my_vpc.id
        cidr_block = "10.0.3.0/24"
    }
    resource "aws_subnet" "pri-subnet-2"{
        vpc_id = aws_vpc.my_vpc.id
        cidr_block = "10.0.4.0/24"
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
            gateway_id = aws_internet_gateway.igw.id
        }
    }
    
    resource  "aws_route_table_association" "public1"{
        subnet_id = aws_subnet.pub-subnet-1.id
        route_table_id = aws_route_table.public_route_table.id
    }
    
    resource "aws_route_table_association" "public2"{
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

    # Create an EC2 instance in public subnet
    resource "aws_instance" "my_ec2"{
        ami = "ami-0149b2da6ceec4bb0"
        instance_type = "t2.micro"
        subnet_id = aws_subnet.pub-subnet-1.id
        associate_public_ip_address = true
        key_name = aws_key_pair.deployer.key_name
        vpc_security_group_ids = [aws_security_group.aws-sg.id]
    }
    

    resource "aws_security_group" "aws-sg"{
        vpc_id = aws_vpc.my_vpc.id
        ingress{
            from_port = 22
            protocol = "tcp"
            to_port = 22
            cidr_blocks = ["0.0.0.0/0"]
        }
        egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    }
}
    resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSd/lGuLgdVF78logPv1HbohY1udHzO5dwLHHVMigiO2vt+nsSNNrqNbioKbtsPwlGfP3Dj6Y/2WFVLY+ktV3aHHmTB0y5+qOZRdDLHzEcd9zZAC8pp7U91kh/mhjTlWb2P1ArWPiWYFOeNNhGDjXPEWDyQsebhLN9A04B5QSqfC5HD4bjcZulEPbTo7zXtQcPFB24/ZDIlHm2soN9S30JwRQ151ORksTmUzZTwz9zffhQ31SQVyeI5aTcLjcOuGfwhyUQpoz2AsIBdCxCNMhsDtQH/0hsbKYtbcJr304xisV61qDFIPuznXCbvRD1BINev/rVHpBaE3yP5I8GIUEygZtREVQt0TpybOtJuT2EIKSXDHfL6VxDggWM3T9xrIRVvzP6o+I+AkfF7TG6edhy01r6bPwb6qKCeJ5n8l7t5eVD/H7JJRY+XsvUa/guFwVD2pEiWcmWE7hw452cgHB5uBJvybRGAah+UTDqlKtT6eQY4CyC/JeoMLwAV85CiRM= shyamgupta@work-laptop"
}
# Create EC2 in Private subnet

    resource "aws_instance" "ec2_private"{
        ami = "ami-0149b2da6ceec4bb0"
        instance_type = "t2.micro"
        subnet_id = aws_subnet.pri-subnet-1.id
        key_name = aws_key_pair.deployer.key_name
        vpc_security_group_ids = [aws_security_group.aws-sg1.id]
    }
    

    resource "aws_security_group" "aws-sg1"{
        vpc_id = aws_vpc.my_vpc.id
        ingress{
            from_port = 22
            protocol = "tcp"
            to_port = 22
            cidr_blocks = ["10.0.1.0/24"]
        }
        egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    }
}

output "ec2_public_ip"{
    value = aws_instance.my_ec2.public_ip
}
