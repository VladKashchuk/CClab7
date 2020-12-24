terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

# base initialization
resource "aws_vpc" "primary_vpc" {
    cidr_block = "7.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = "forLab7"
    }
}

resource "aws_subnet" "subnet_1" {
    vpc_id = aws_vpc.primary_vpc.id
    cidr_block = "7.0.0.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-1a"
    tags = {
        Name = "forLab7_1"
    }
}

resource "aws_subnet" "subnet_2" {
    vpc_id = aws_vpc.primary_vpc.id
    cidr_block = "7.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-1b"
    tags = {
        Name = "forLab7_2"
    }
}
# internet access
resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.primary_vpc.id
}
# route table
resource "aws_route_table" "rtb" {
    vpc_id = aws_vpc.primary_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id

    }
}

# assing rtb -> subnets
resource "aws_route_table_association" "subnet_1_asoc" {
    route_table_id = aws_route_table.rtb.id
    subnet_id = aws_subnet.subnet_1.id
}


resource "aws_route_table_association" "subnet_2_asoc" {
    route_table_id = aws_route_table.rtb.id
    subnet_id = aws_subnet.subnet_1.id
}

# security group for database
resource "aws_security_group" "sg" {
    name = "forLab7"
    vpc_id = aws_vpc.primary_vpc.id

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# special subnet group (for db required!!)
resource "aws_db_subnet_group" "subnet_group" {
  name = "for-lab7"
  subnet_ids = [ aws_subnet.subnet_1.id, aws_subnet.subnet_2.id ]

  tags = {
    Name = "forLab7"
  }
}

# db instance
resource "aws_db_instance" "db" {
  publicly_accessible = true
  vpc_security_group_ids = [aws_security_group.sg.id]
  db_subnet_group_name = aws_db_subnet_group.subnet_group.id
  allocated_storage = 5
  storage_type = "gp2"
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  name = "forlabseven"
  username = "testuser"
  password = "Lgfd!53Kjst34"
  parameter_group_name = "default.mysql5.7"
}
