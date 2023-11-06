# IAM Role for EC2 Instances
resource "aws_iam_role" "ec2_instance_role" {
  name = "EC2InstanceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Policy to Allow GetSecretValue
resource "aws_iam_policy" "secretsmanager_policy" {
  name        = "SecretsManagerPolicy"
  description = "Policy to allow GetSecretValue from Secrets Manager"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = ["secretsmanager:GetSecretValue"],
        Effect = "Allow",
        Resource = aws_secretsmanager_secret.secretdb.arn,
      },
    ],
  })
}

# Attach the Inline Policy to the IAM Role
resource "aws_iam_policy_attachment" "secretsmanager_attachment" {
  name       = "SecretsManagerAttachment"
  policy_arn = aws_iam_policy.secretsmanager_policy.arn
  roles      = [aws_iam_role.ec2_instance_role.name]
}

# IAM Role Policy Attachment
resource "aws_iam_instance_profile" "instance_profile" {
  name = "EC2InstanceProfile"
  role = aws_iam_role.ec2_instance_role.name
}

# Here is ami_id that was created with packer
data "aws_ami" "ami" {
  most_recent = true
  owners = ["self"]
  filter {
    name = "name"
    values = ["test"]
  }
}

# Launch Template
resource "aws_launch_template" "launch_templ" {
  name_prefix   = "launch_templ"
  image_id      = data.aws_ami.ami.id
  instance_type = "t2.micro"

  # Attach the IAM instance profile to the Launch Template
  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.Public_subnet1.id
    security_groups             = [aws_security_group.SGtemplate.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "instance" # Name for the EC2 instances
    }
  }
}

# Auto Scaling Group with Launch Template
resource "aws_autoscaling_group" "ASG" {
  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  launch_template {
    id      = aws_launch_template.launch_templ.id
    version = "$Latest"
  }

  vpc_zone_identifier  = [aws_subnet.Public_subnet1.id]
  //key_name            = "my_key_name"
  name                = "ASG"
  health_check_grace_period = 300
  min_elb_capacity    = 0
  //max_elb_capacity    = 0
  health_check_type   = "ELB"
  termination_policies = ["Default"]
  target_group_arns   = [aws_lb_target_group.my_target_group.arn]
}
# Application Load Balancer
resource "aws_lb" "my_alb" {
  name               = "LB"
  internal           = false  # Set to true if you need an internal ALB
  load_balancer_type = "application"
  subnets            = [aws_subnet.Public_subnet1.id, aws_subnet.Public_subnet2.id]
  enable_deletion_protection = false  # Enable deletion protection if needed

  enable_http2        = true

  enable_cross_zone_load_balancing = true

  security_groups = [aws_security_group.ALBSecurityGroup.id]
  tags = {
    Name = "LB"
  }
}

# ALB Target Group
resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demovpc.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
resource "aws_lb_listener" "my_alb_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port             = 80
  protocol         = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}


