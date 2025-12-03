// Infra/packer/app-ami.pkr.hcl

packer {
  required_version = ">= 1.8.0"

  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.3.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

// Docker image in Docker Hub, passed from GitHub Actions
// e.g. akshithanandre/spring-boot-demo:latest
variable "docker_image" {
  type = string
}

// Base AMI – Amazon Linux 2 in us-east-1
variable "source_ami" {
  type    = string
  default = "ami-0c02fb55956c7d316"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_name_prefix" {
  type    = string
  default = "spring-docker-app"
}

source "amazon-ebs" "docker_app" {
  region        = var.aws_region
  source_ami    = var.source_ami
  instance_type = var.instance_type
  ssh_username  = "ec2-user"

  ami_name = "${var.ami_name_prefix}-${formatdate("YYYYMMDDhhmmss", timestamp())}"

  associate_public_ip_address = true

  tags = {
    Name = var.ami_name_prefix
    Role = "spring-boot-docker-app"
  }
}

build {
  name    = "spring-docker-app-build"
  sources = ["source.amazon-ebs.docker_app"]

  # 1) Install Docker on Amazon Linux 2
  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker -y || sudo yum install -y docker",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo usermod -aG docker ec2-user",
    ]
  }

  # 2) Pull your Docker image & create a systemd service to run it
  provisioner "shell" {
    inline = [
      # Pull image
      "sudo docker pull ${var.docker_image}",

      # Create systemd unit file
      "echo '[Unit]' | sudo tee /etc/systemd/system/app.service",
      "echo 'Description=Dockerized Spring Boot App' | sudo tee -a /etc/systemd/system/app.service",
      "echo 'After=docker.service' | sudo tee -a /etc/systemd/system/app.service",
      "echo '' | sudo tee -a /etc/systemd/system/app.service",
      "echo '[Service]' | sudo tee -a /etc/systemd/system/app.service",
      "echo 'Restart=always' | sudo tee -a /etc/systemd/system/app.service",
      "echo 'ExecStart=/usr/bin/docker run --rm --name app -p 8080:8080 ${var.docker_image}' | sudo tee -a /etc/systemd/system/app.service",
      "echo 'ExecStop=/usr/bin/docker stop app' | sudo tee -a /etc/systemd/system/app.service",
      "echo '' | sudo tee -a /etc/systemd/system/app.service",
      "echo '[Install]' | sudo tee -a /etc/systemd/system/app.service",
      "echo 'WantedBy=multi-user.target' | sudo tee -a /etc/systemd/system/app.service",

      # Enable service
      "sudo systemctl daemon-reload",
      "sudo systemctl enable app.service",
    ]
  }
}
