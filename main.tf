// Providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

// Cloud
provider "aws" {
  region = "us-east-1"
  profile = "terraform"
}

// Virtual Private Cloud
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc"
  }
}

// Virtual Private Cloud security group
resource "aws_security_group" "vpc_sg" {
  name        = "vpc-sg"
  description = "VPC security group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

// Domain to direct requests to load balancer
resource "aws_route53_record" "domain" {
  zone_id = var.route53_zone_id
  name    = "griffindow.com"
  type    = "A"

  alias {
    name                   = aws_lb.worker_lb.dns_name
    zone_id                = aws_lb.worker_lb.zone_id
    evaluate_target_health = false
  }
}

