packer {
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

source "amazon-ebs" "app" {
  region         = var.aws_region
  source_ami     = var.source_ami
  instance_type  = var.instance_type
  ssh_username   = "ec2-user"

  ami_name       = "spring-docker-app-{{timestamp}}"

  // you can add vpc_id / subnet_id / security_group_id later if needed
}

build {
  name    = "spring-docker-app"
  sources = ["source.amazon-ebs.app"]

  // Install Docker
  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker -y || sudo yum install -y docker",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo usermod -aG docker ec2-user",
    ]
  }

  // Pull your image & configure systemd to run it
  provisioner "shell" {
    inline = [
      "sudo docker pull ${var.docker_image}",

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

      "sudo systemctl daemon-reload",
      "sudo systemctl enable app.service",
    ]
  }
}
