🚀 Spring Boot + AWS Auto-Scaling Deployment Pipeline

This project automates the deployment of a Spring Boot application to AWS using GitHub Actions, Packer, Terraform, ALB, and Auto Scaling Groups (ASG).

🔧 What This Project Does

Builds and tests the Spring Boot app using GitHub Actions

Creates a Docker image and pushes it to Docker Hub

Uses Packer to build an AMI that contains the app

Uses Terraform to create:

VPC, subnets, security groups

Application Load Balancer (ALB)

Launch Template with the AMI

Auto Scaling Group (ASG)

ASG does rolling deployments when a new AMI is created

ASG automatically scales out/in based on CPU utilization

🌐 How Traffic Works

ALB receives traffic on port 80

Routes traffic to EC2 instances in the Target Group

Health checks ensure only healthy instances serve traffic

📈 Auto Scaling Behavior

Scale OUT when CPU > 60%

Scale IN when CPU < 20%

Minimum instances: 1

Maximum: 3
Desired: 1

🏗 CI/CD Pipeline Flow

Push Code → Build & Test → Docker Build → Packer AMI → Terraform Deploy → ASG Rolling Update


