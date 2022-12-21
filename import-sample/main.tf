terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    
  }
  
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "tf_vpc" {
  cidr_block       = "10.5.0.0/16"
  instance_tenancy = "default"
  tags = {
    "Name" = "tf-vpc"
  }
  tags_all = {
    "Name" = "tf-vpc"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.tf_vpc.id
  availability_zone = "ap-south-1a"
  cidr_block        = "10.5.0.0/24"
  tags = {
    "Name" = "Subnet-1"
  }
  tags_all = {
    "Name" = "Subnet-1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.tf_vpc.id
  availability_zone = "ap-south-1b"
  cidr_block        = "10.5.1.0/24"
  tags = {
    "Name" = "Subnet-2"
  }
  tags_all = {
    "Name" = "Subnet-2"
  }
}

resource "aws_internet_gateway" "tf_vpc_igw" {
  vpc_id = aws_vpc.tf_vpc.id
  tags = {
    "Name" = "tf-vpc-igw"
  }
  tags_all = {
    "Name" = "tf-vpc-igw"
  }
}

resource "aws_security_group" "tf_vpc_sg" {
  vpc_id      = aws_vpc.tf_vpc.id
  description = "default VPC security group"
  egress = [
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
  ingress = [
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description      = ""
      from_port        = 22
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 22
    },
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description      = ""
      from_port        = 3389
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 3389
    },
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description      = ""
      from_port        = 80
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 80
    },
    {
      cidr_blocks      = []
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = true
      to_port          = 0
    },
  ]
  name = "default"
}

resource "aws_instance" "vm1" {
  ami                         = "ami-08bd8e5c51334492e"
  associate_public_ip_address = true
  availability_zone           = "ap-south-1a"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet1.id
}

resource "aws_instance" "vm2" {
  ami                         = "ami-08bd8e5c51334492e"
  associate_public_ip_address = true
  availability_zone           = "ap-south-1a"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet1.id
  key_name                    = "MyWinKey"
  security_groups             = [aws_security_group.tf_vpc_sg.id]
}
