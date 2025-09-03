data "aws_caller_identity" "current" {}

data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group" "svc_sg" {
  name        = "microservices-sg"
  description = "Allow SSH and app ports"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_cidr]
  }

  # Frontend (host:8080 -> container:80)
  ingress {
    description = "Frontend"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_client_cidr]
  }

  # Backend exposed (optional)
  ingress {
    description = "Backend"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_client_cidr]
  }

  # Logger exposed (optional)
  ingress {
    description = "Logger"
    from_port   = 6000
    to_port     = 6000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_client_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amzn2.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = element(data.aws_subnet_ids.default.ids, 0)
  vpc_security_group_ids = [aws_security_group.svc_sg.id]

  user_data = templatefile("${path.module}/user_data.sh", {
    dockerhub_username = var.dockerhub_username,
    tag                = var.image_tag
  })

  tags = {
    Name = "microservices-app"
  }
}

output "public_ip" {
  description = "Public IP of the instance"
  value       = aws_instance.app.public_ip
}

output "frontend_url" {
  description = "Frontend URL"
  value       = "http://${aws_instance.app.public_ip}:8080"
}

