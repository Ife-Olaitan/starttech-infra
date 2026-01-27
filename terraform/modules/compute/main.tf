# Get the latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Launch Template
resource "aws_launch_template" "main" {
  name          = "${var.name}-lt"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.backend.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.backend_server.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    # Create log directory
    mkdir -p /var/log/backend
    chmod 755 /var/log/backend

    # Install Docker
    apt-get update
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker

    # Pull and run the backend container
    docker pull ${var.dockerhub_image}:latest
    docker run -d \
      --name backend \
      --restart always \
      -p ${var.app_port}:${var.app_port} \
      -v /var/log/backend:/var/log/backend \
      -e PORT="${var.app_port}" \
      -e LOG_LEVEL="INFO" \
      -e LOG_FORMAT="json" \
      -e JWT_EXPIRATION_HOURS="72" \
      -e DB_NAME="much_todo_db" \
      -e MONGO_URI="${var.mongo_uri}" \
      -e JWT_SECRET_KEY="${var.jwt_secret}" \
      -e ENABLE_CACHE="true" \
      -e REDIS_ADDR="${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379" \
      ${var.dockerhub_image}:latest

    # Install CloudWatch Agent
    wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
    dpkg -i amazon-cloudwatch-agent.deb

    # Configure CloudWatch Agent
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CONFIG'
    {
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/backend/app.log",
                "log_group_name": "${var.log_group_name}",
                "log_stream_name": "{instance_id}"
              }
            ]
          }
        }
      }
    }
    CONFIG

    # Start CloudWatch Agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config \
      -m ec2 \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
      -s

  EOF
  )

  tags = {
    Name = "${var.name}-lt"
  }
}

# ASG
resource "aws_autoscaling_group" "main" {
  name                = "${var.name}-asg"
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size
  target_group_arns   = [aws_lb_target_group.main.arn]
  vpc_zone_identifier = var.private_subnet_ids
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-backend"
    propagate_at_launch = true
  }
}

# Scale up when CPU > 70%
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.name}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.main.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
}

# Scale down when CPU < 30%
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.name}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.main.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.name}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
}


# ALB SG
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-alb-sg"
  }
}


resource "aws_security_group" "backend" {
  name        = "${var.name}-backend-sg"
  description = "Security group for backend server"
  vpc_id      = var.vpc_id

  ingress {
    description     = "APP traffic from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # ingress {
  #   description     = "SSH from Bastion SG"
  #   from_port       = 22
  #   to_port         = 22
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.bastion.id]
  # }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-backend-sg"
  }
}

# Redis SG
resource "aws_security_group" "redis" {
  name        = "${var.name}-redis-sg"
  description = "Security group for Redis"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from backend"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-redis-sg"
  }
}

# ALB
resource "aws_lb" "main" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.name}-alb"
  }
}

# ALB Target Group
resource "aws_lb_target_group" "main" {
  name     = "${var.name}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = {
    Name = "${var.name}-tg"
  }
}

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# IAM Role for EC2 to access Cloudwatch
resource "aws_iam_role" "backend_server" {
  name = "${var.name}-backend-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Policy attachment
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.backend_server.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance Profile - Connects role to EC2
resource "aws_iam_instance_profile" "backend_server" {
  name = "${var.name}-backend-server-profile"
  role = aws_iam_role.backend_server.name
}

# Redis Subnet
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.name}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids
}

# Redis Replication Group
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.name}-redis"
  description                = "Redis for sessions and caching"
  node_type                  = var.node_type
  num_cache_clusters         = 2
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.redis.id]
  automatic_failover_enabled = true
  multi_az_enabled           = true

  tags = {
    Name = "${var.name}-redis"
  }
}

# IAM Role for GitHub Actions Backend Deploy
resource "aws_iam_role" "github_actions_backend" {
  name = "${var.name}-github-actions-backend"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.github_oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
        }
      }
    }]
  })
}

# Policy for ASG rolling update
resource "aws_iam_role_policy" "github_actions_backend" {
  name = "backend-deploy-policy"
  role = aws_iam_role.github_actions_backend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:StartInstanceRefresh",
          "autoscaling:DescribeInstanceRefreshes",
          "autoscaling:DescribeAutoScalingGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

