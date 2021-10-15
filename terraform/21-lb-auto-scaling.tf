resource "aws_lb" "pizza_lb" {
  name               = "pizza-lb"
  subnets            = [aws_subnet.pizza_subnet_a.id, aws_subnet.pizza_subnet_b.id]
  ip_address_type    = "ipv4"
  security_groups    = [aws_security_group.pizza_lb_security.id]
  load_balancer_type = "application"

  tags = {
    Owner = var.owner
  }
}

// Allow all traffic from port 80 (HTTP) and all outbound traffic to other resources
resource "aws_security_group" "pizza_lb_security" {
  name                   = "pizza-lb-sg"
  description            = "Security group for pizza load balancer"
  vpc_id                 = aws_vpc.pizza_vpc.id
  revoke_rules_on_delete = true

  ingress {
    description      = "Allow inbound traffic from anywhere on load balancer listener port 80"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "Allow outbound traffic to anywhere"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Owner : var.owner
  }
}

resource "aws_lb_listener" "pizza_lb_listener" {
  tags = {
    Owner = var.owner
  }

  load_balancer_arn = aws_lb.pizza_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pizza_tg.arn
  }
}

// Create Load Balancer target group which will containt EC2 instance
resource "aws_lb_target_group" "pizza_tg" {
  tags = {
    Owner = var.owner
  }

  name     = "pizza-lb-tg"
  port     = "3000"
  protocol = "HTTP"
  vpc_id   = aws_vpc.pizza_vpc.id

  health_check {
    path    = "/"
    matcher = "200,202"
  }

  stickiness {
    type = "lb_cookie"
  }
}

// Add EC2 instance to load balancer target group
resource "aws_lb_target_group_attachment" "pizza_tg_attach_ec2" {
  target_group_arn = aws_lb_target_group.pizza_tg.arn
  target_id        = aws_instance.pizza_instance.id
  port             = "3000"
}

// Retrieve ID of AMI image created from EC2 instance
// (with all packages and dependencies already installed)

data "aws_ami" "pizza_app_base_ec2_image" {
  owners      = ["self"]
  most_recent = true
  filter {
    name   = "image-id"
    values = ["ami-012c27d2ee208e40b"]
  }
}

// Launch configuration with AMI image (above) to create Auto Scaling Group,
// which will in turn use to create new EC2 instances with all necessary packages
// and dependencies already installed
resource "aws_launch_configuration" "pizza_lc" {
  name            = "pizza-lc"
  image_id        = data.aws_ami.pizza_app_base_ec2_image.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.pizza_security.id]
  key_name        = aws_key_pair.generated_key.key_name
  // key pair (to enable you to ssh into it, not recommended for production)
}

// Attach ASG policy to ASG
// ASG will increase and decrease instances to meet this number (avg network out (bytes))
resource "aws_autoscaling_policy" "pizza_asg_policy_config" {
  name                   = "pizza-asg-policy-config"
  autoscaling_group_name = aws_autoscaling_group.pizza_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageNetworkOut"
    }

    target_value = 50000
  }
}

// configure ASG group size, desired, min, max
// specify target group
resource "aws_autoscaling_group" "pizza_asg" {
  name                = "pizza-asg"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 4
  health_check_grace_period = 300
  health_check_type         = "ELB"
  target_group_arns   = [aws_lb_target_group.pizza_tg.arn]
  vpc_zone_identifier = [aws_subnet.pizza_subnet_a.id, aws_subnet.pizza_subnet_b.id]

  launch_configuration = aws_launch_configuration.pizza_lc.name

  instance_refresh {
    strategy = "Rolling"
    triggers = ["tag"]
  }

  tag {
    key                 = "Owner"
    propagate_at_launch = false
    value               = var.owner
  }
}
