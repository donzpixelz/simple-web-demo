provider "aws" {
  region = "us-east-2"
}

# Fetch your current public IP dynamically
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

locals {
  my_ip = chomp(data.http.my_ip.response_body)
}

# Security group allowing HTTP inbound on port 8080 and SSH from your IP
resource "aws_security_group" "web_sg" {
  name        = "simple-web-demo-sg"
  description = "Allow HTTP 8080 and SSH from my IP"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${local.my_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance
resource "aws_instance" "web" {
  ami           = "ami-096566f39a31a283e"
  instance_type = "t3.micro"
  key_name      = var.ssh_key_name

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              sudo service docker start
              sudo docker rm -f simple-web-demo || true
              sudo docker run -d --name simple-web-demo -p 8080:80 --restart unless-stopped ${var.dockerhub_username}/simple-web-demo:latest
              EOF

  tags = {
    Name = "simple-web-demo"
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
