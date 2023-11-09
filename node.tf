

// Security group for all nodes
resource "aws_security_group" "nodes_sg" {
  name        = "nodes-sg"
  description = "Security group for Kubernetes nodes"
  vpc_id      = aws_vpc.vpc.id

  // Allow SSH from the bastion instance
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.bastion.private_ip}/32"]
  }

  // Allow all ICMP traffic for ping and other diagnostics
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["${aws_instance.bastion.private_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Operating system for all nodes
data "aws_ami" "debian_12" {
  most_recent = true
  filter {
    name   = "name"
    values = ["debian-12*"]
  }
}
