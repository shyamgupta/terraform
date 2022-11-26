terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.40.0"
    }
  }
  backend "s3" {
    bucket         = var.s3_bucket_name 
    key            = var.s3_key
    region         = var.aws_region
    dynamodb_table = var.dynamodb_table_name
  }
}

resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name = var.dynamodb_table_name
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20
 
  attribute {
    name = "LockID"
    type = "S"
  }
}

provider "aws" {
  # Configuration options
  region = var.aws_region
  shared_credentials_file = "~/.aws/credentials"
}

resource "aws_vpc" "my_vpc"{
  cidr_block = var.vpc_cidr_block
}

resource "aws_subnet" "pub_subnet1"{
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = var.pub_subnet1_cidr
}

resource "aws_subnet" "pub_subnet2"{
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = var.pub_subnet2_cidr
}

resource "aws_subnet" "pri_subnet1"{
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = var.pri_subnet1_cidr
}

resource "aws_subnet" "pri_subnet2"{
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = var.pri_subnet2_cidr
}

resource "aws_internet_gateway" "igw"{
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_eip" "eip"{
  vpc = true
}

resource "aws_nat_gateway" "nat_gw"{
  allocation_id = aws_eip.eip.id
  subnet_id = aws_subnet.pri_subnet1.id
}

resource "aws_route_table" "pub_rt_table"{
  vpc_id = aws_vpc.my_vpc.id
  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public1"{
  subnet_id = aws_subnet.pub_subnet1.id
  route_table_id = aws_route_table.pub_rt_table.id
}


resource "aws_route_table_association" "public2"{
  subnet_id = aws_subnet.pub_subnet2.id
  route_table_id = aws_route_table.pub_rt_table.id
}

resource "aws_route_table" "pri_rt_table"{
  vpc_id = aws_vpc.my_vpc.id
  route{
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
}


resource "aws_route_table_association" "private1"{
  subnet_id = aws_subnet.pri_subnet1.id
  route_table_id = aws_route_table.pri_rt_table.id
}
resource "aws_route_table_association" "public2"{
  subnet_id = aws_subnet.pub_subnet2.id
  route_table_id = aws_route_table.pri_rt_table.id
}

resource "aws_instance" "pub_ec2"{
  ami = var.ami
  instance_type = var.ec2_instance_type
  subnet_id = aug_subnet.pub_subnet1.id
  associate_public_ip_address = true
  key_name = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.aws_pub_sg.id]
}

resource "aws_instance" "pri_ec2"{
  ami = var.ami
  instance_type = var.ec2_instance_type
  subnet_id = aug_subnet.pri_subnet1.id
  key_name = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.aws_pri_sg.id]
}
resource "aws_security_group" "aws_pub_sg"{
  vpc_id = aws_vpc.my_vpc.id
  ingress{
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_security_group" "aws_pri_sg"{
  vpc_id = aws_vpc.my_vpc.id
  ingress{
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = [var.pub_subnet1]
  }
  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer"{
  key_name = "deployer_key"
  public_key = var.ssh_key
}

output "ec2_public_ip"{
  value  = aws_instance.pub_ec2.public_ip
}
