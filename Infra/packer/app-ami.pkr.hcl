packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

source "amazon-ebs" "app" {
  region                  = var.aws_region
  instance_type           = "t2.micro"
  ami_name                = "spring-boot-demo-{{timestamp}}"
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["137112412989"] # Amazon
    most_recent = true
  }
  ssh_username            = "ec2-user"
}

build {
  name    = "spring-boot-demo"
  sources = ["source.amazon-ebs.app"]

  provisioner "file" {
    source      = "app.jar"
    destination = "/home/ec2-user/app.jar"
  }

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install java-openjdk17 -y || sudo yum install -y java-17-openjdk",
      "sudo mv /home/ec2-user/app.jar /opt/app.jar",
      "echo '[Unit]' | sudo tee /etc/systemd/system/app.service",
      "echo 'Description=Spring Boot App' | sudo tee -a /etc/systemd/system/app.service",
      "echo '[Service]' | sudo tee -a /etc/systemd/system/app.service",
      "echo 'ExecStart=/usr/bin/java -jar /opt/app.jar' | sudo tee -a /etc/systemd/system/app.service",
      "echo 'Restart=always' | sudo tee -a /etc/systemd/system/app.service",
      "echo '[Install]' | sudo tee -a /etc/systemd/system/app.service",
      "echo 'WantedBy=multi-user.target' | sudo tee -a /etc/systemd/system/app.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable app.service"
    ]
  }
}
