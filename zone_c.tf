// Private Subnet
resource "aws_subnet" "subnet_c" {
  availability_zone       = "us-east-1c"
  cidr_block              = "10.0.3.0/24"
  vpc_id                  = aws_vpc.vpc.id

  tags = {
    Name = "subnet-c"
  }
}

// Control node
resource "aws_instance" "control_node_c" {
  depends_on = [aws_instance.bastion]
  count = 0
  ami           = data.aws_ami.debian_12.id
  instance_type = "t4g.nano"
  subnet_id     = aws_subnet.subnet_c.id
  key_name      = "nodes"
  vpc_security_group_ids = [aws_security_group.nodes_sg.id]

  // Run kubeadmin join for the rest of the control nodes
  connection {
    type        = "ssh"
    user        = "admin" # replace with the appropriate username for your AMI
    private_key = file("~/.ssh/nodes")
    host        = self.public_ip

    bastion_host        = aws_instance.bastion.public_ip
    bastion_private_key = file("~/.ssh/id_rsa")
    bastion_user        = "admin" # replace with the appropriate username for your bastion AMI
  }

  provisioner "remote-exec" {
    inline = [
      "sudo kubeadm join --token ${var.cluster_control_join_token} ${aws_instance.control_node_b[0].private_ip}:6443"
    ]
  }

  tags = {
    Name = "control-node-c"
  }
}

// Worker nodes
resource "aws_instance" "worker_node_c" {
  count         = 0
  ami           = data.aws_ami.debian_12.id # Replace with appropriate AMI ID
  instance_type = "t4g.small"
  key_name = "nodes"
  security_groups = [aws_security_group_rule.allow_alb_traffic.id, aws_security_group.nodes_sg.id]

  tags = {
    Name = "Worker node c instance ${count.index}"
  }

  connection {
    type        = "ssh"
    user        = "admin"
    private_key = file("~/.ssh/nodes")
    host        = self.public_ip

    bastion_host        = aws_instance.bastion.public_ip
    bastion_private_key = file("~/.ssh/id_rsa")
    bastion_user        = "admin"
  }
  
  provisioner "remote-exec" {
    inline = [
      "sudo kubeadm join --token ${var.cluster_worker_join_token} ${aws_instance.control_node_c[0].private_ip}:6443"
    ]
  }

  lifecycle {
    create_before_destroy = true
  }
}