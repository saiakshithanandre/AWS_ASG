############################################
# Security groups
############################################

# SG for ALB - public HTTP
resource "aws_security_group" "alb_sg" {
  name        = "${var.app_name}-alb-sg"
  description = "Allow HTTP from internet to ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-alb-sg"
  }
}

# SG for app instances - only ALB can hit app_port
resource "aws_security_group" "app_sg" {
  name        = "${var.app_name}-app-sg"
  description = "Allow traffic from ALB to app instances"
  vpc_id      = var.vpc_id

  ingress {
    description = "Traffic from ALB"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    security_groups = [
      aws_security_group.alb_sg.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-app-sg"
  }
}

############################################
# ALB + Target group
############################################

resource "aws_lb" "app_alb" {
  name               = "${var.app_name}-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.alb_sg.id]

  tags = {
    Name = "${var.app_name}-alb"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "${var.app_name}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }

  tags = {
    Name = "${var.app_name}-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

############################################
# Launch template
############################################

resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.app_name}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # Optional: start app service if not already
  user_data = base64encode(<<EOF
#!/bin/bash
systemctl start app.service || true
EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.app_name}-instance"
    }
  }

  tags = {
    Name = "${var.app_name}-lt"
  }
}

############################################
# Auto Scaling Group (ALB health + CPU scaling)
############################################

resource "aws_autoscaling_group" "app_asg" {
  name                = "${var.app_name}-asg"
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = var.public_subnet_ids

  # Use ALB health checks
  health_check_type         = "ELB"
  health_check_grace_period = 60

  target_group_arns = [aws_lb_target_group.app_tg.arn]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.app_name}-asg-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  # Instance refresh = rolling deployments when launch template (AMI) changes
  instance_refresh {
    strategy = "Rolling"

    preferences {
      instance_warmup        = 60
      min_healthy_percentage = 80
    }

    triggers = ["launch_template"]
  }

  depends_on = [aws_lb_listener.http]
}

############################################
# CPU-based scaling policies
############################################

# 🔼 Scale out when high CPU
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.app_name}-scale-out"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = var.scale_out_adjustment
  cooldown               = 120
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.app_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_out_cpu_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  alarm_description = "Scale out if average CPU > ${var.scale_out_cpu_threshold}%"
  alarm_actions     = [aws_autoscaling_policy.scale_out.arn]
}

# 🔽 Scale in when low CPU
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.app_name}-scale-in"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = var.scale_in_adjustment   # usually -1
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.app_name}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 4
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_in_cpu_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  alarm_description = "Scale in if average CPU < ${var.scale_in_cpu_threshold}%"
  alarm_actions     = [aws_autoscaling_policy.scale_in.arn]
}
