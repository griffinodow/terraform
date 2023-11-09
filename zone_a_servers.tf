// Bastion
resource "aws_instance" "bastion" {
  depends_on = [ aws_subnet.public_subnet_a ]
  ami           = data.aws_ami.debian_12.id
  instance_type = "t4g.nano"

  // Use the public subnet for the bastion instance
  subnet_id = aws_subnet.public_subnet_a.id

  key_name               = "griffinsmacbook"
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  // Add a public IP to the bastion instance
  associate_public_ip_address = true

  connection {
    user        = "admin"
    host        = self.public_ip
    private_key = "${file("~/.ssh/id_rsa")}"
  }

  provisioner "file" {
    source      = "~/.ssh/nodes"
    destination = "/home/admin/.ssh/nodes"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/admin/.ssh/nodes",
    ]
  }

  tags = {
    Name = "bastion"
  }
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.vpc.id

  // Allow SSH from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Control node
resource "aws_instance" "control_node_a" {
  depends_on    = [aws_instance.bastion]
  count         = 1
  ami           = data.aws_ami.debian_12.id
  instance_type = "t4g.nano"
  subnet_id     = aws_subnet.private_subnet_a.id
  key_name      = "nodes"
  vpc_security_group_ids = [aws_security_group.nodes_sg.id]


  connection {
    type        = "ssh"
    user        = "admin" # replace with the appropriate username for your AMI
    private_key = file("~/.ssh/nodes")
    host        = self.private_ip

    bastion_host        = aws_instance.bastion.public_ip
    bastion_private_key = file("~/.ssh/id_rsa")
    bastion_user        = "admin" # replace with the appropriate username for your bastion AMI
  }

  // Install and configure kubeadm, kubelet and docker
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update && sudo apt-get install -y apt-transport-https curl",
      "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
      "cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list\ndeb https://apt.kubernetes.io/ kubernetes-xenial main\nEOF",
      "sudo apt-get update",
      "sudo apt-get install -y kubelet kubeadm kubectl docker.io"
    ]
  }

  // Run kubeadmin init only for the first control node
  provisioner "remote-exec" {
    inline = [
      "sudo kubeadm init --pod-network-cidr=10.244.0.0/16 > ./kubeinit.out"
    ]
  }

  // Configure kubectl to use the cluster on the first control node
  provisioner "remote-exec" {
    inline = [
      "mkdir -p $HOME/.kube && cp ./kubeinit.out $HOME/.kube/config && chmod 0600 $HOME/.kube/config"
    ]
  }

  // Install flannel for pod network on the first control node
  provisioner "remote-exec" {
    inline = [
      "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"
    ]
  }

  tags = {
    Name = "control-node-a"
  }
}

// Worker nodes
resource "aws_instance" "worker_node_a" {
  count         = 1
  ami           = data.aws_ami.debian_12.id 
  instance_type = "t4g.small"
  key_name = "nodes"
  security_groups = [aws_security_group_rule.allow_alb_traffic.id, aws_security_group.nodes_sg.id]

  tags = {
    Name = "Worker node a instance ${count.index}"
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
      "sudo kubeadm join --token ${var.cluster_worker_join_token} ${aws_instance.control_node_a[0].private_ip}:6443"
    ]
  }

  lifecycle {
    create_before_destroy = true
  }
}
