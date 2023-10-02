provider "aws" {
  region = var.region
}

# ECR Repository
resource "aws_ecr_repository" "hello_world_repository" {
  name                 = "hello-world-repository"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Security Group
resource "aws_security_group" "hello_world_sg" {
  name        = "hello-world-sg"
  description = "Security Group for hello-world-service"
  vpc_id      = var.vpc_id

  ingress {
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
}

# IAM Role for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Effect = "Allow",
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.ec2_role.name
}

# EC2 Launch Configuration
resource "aws_launch_configuration" "hello_world_lc" {
  name             = "hello-world-lc"
  image_id         = var.ami_id
  instance_type    = var.instance_type
  security_groups  = [aws_security_group.hello_world_sg.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              chkconfig docker on
              
              # Authenticate to ECR
              $(aws ecr get-login --no-include-email --region ${var.region})
              
              # Pull the image from ECR
              docker pull ${aws_ecr_repository.hello_world_repository.repository_url}:${var.image_tag}
              
              # Run the Docker container
              docker run -d -p 80:80 ${aws_ecr_repository.hello_world_repository.repository_url}:${var.image_tag}
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

# AutoScaling Group
resource "aws_autoscaling_group" "hello_world_asg" {
  name                 = "hello-world-asg"
  launch_configuration = aws_launch_configuration.hello_world_lc.name
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  vpc_zone_identifier  = var.subnets

  tags = [
    {
      key                 = "Name"
      value               = "hello-world-instance"
      propagate_at_launch = true
    }
  ]
}

# Load Balancer
resource "aws_lb" "hello_world_lb" {
  name               = "hello-world-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.hello_world_sg.id]
  subnets            = var.subnets

  enable_deletion_protection = false
  enable_cross_zone_load_balancing   = true
  idle_timeout                       = 400
  enable_http2                       = true
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.hello_world_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }
}

resource "aws_lb_target_group" "front_end" {
  name     = "frontend"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.hello_world_asg.name
  alb_target_group_arn   = aws_lb_target_group.front_end.arn
}

# Cloud watch metrics to monitor
# High CPU Usage on EC2
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "High CPU Usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric checks if EC2 CPU utilization exceeds 85% over two consecutive periods"
  alarm_actions       = [aws_sns_topic.cpu_alerts.arn]
  dimensions = {
    InstanceId = aws_instance.my_instance.id
  }
}

# High Latency on ALB
resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "High ALB Latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "0.5"
  alarm_description   = "This metric checks if ALB latency exceeds 0.5 seconds over two consecutive periods"
  alarm_actions       = [aws_sns_topic.latency_alerts.arn]
  dimensions = {
    LoadBalancer = aws_lb.my_alb.arn_suffix
  }
}

# Setup notifications with SNS
resource "aws_sns_topic" "cpu_alerts" {
  name = "cpu-alerts"
}

resource "aws_sns_topic" "latency_alerts" {
  name = "latency-alerts"
}

resource "aws_sns_topic_subscription" "cpu_notification" {
  topic_arn = aws_sns_topic.cpu_alerts.arn
  protocol  = "email"
  endpoint  = "your-email@example.com"
}

resource "aws_sns_topic_subscription" "latency_notification" {
  topic_arn = aws_sns_topic.latency_alerts.arn
  protocol  = "email"
  endpoint  = "your-email@example.com"
}
