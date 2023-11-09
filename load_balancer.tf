

# Load balancer
resource "aws_lb" "worker_lb" {
  name               = "worker-loadbalancer"
  internal           = false
  security_groups    = [aws_security_group.alb_sg.id]

  subnets = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id, aws_subnet.private_subnet_c.id]
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "allow_alb_traffic" {
  security_group_id = aws_security_group.alb_sg.id

  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}
