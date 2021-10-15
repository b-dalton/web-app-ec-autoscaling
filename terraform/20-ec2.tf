locals {
  subnet_ids_list         = [aws_subnet.pizza_subnet_a.id, aws_subnet.pizza_subnet_b.id]
  subnet_ids_random_index = random_id.index.dec % length(local.subnet_ids_list)
  instance_subnet_id      = local.subnet_ids_list[local.subnet_ids_random_index]
}

resource "random_id" "index" {
  byte_length = 2
}

// Create a private key
resource "tls_private_key" "pizza_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

// Create key pair from private key to use to SSH into EC2 instance
resource "aws_key_pair" "generated_key" {
  key_name   = "pizza-keys"
  public_key = tls_private_key.pizza_key.public_key_openssh
}


// Store private key in Parameter Store
resource "aws_ssm_parameter" "pizza_ec2_server_key" {
  tags = {
    Owner = var.owner
  }

  name        = "/ec2/pizza_instance_key"
  type        = "SecureString"
  description = "The private key for the Pizza EC2 Instance"
  value       = tls_private_key.pizza_key.private_key_pem
}

// This grabs the latest version of Amazon Linux 2
data "aws_ami" "latest_amazon_linux_2" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Use Amazon Linux 2 AMI (HVM) SSD Volume Type
  name_regex = "^amzn2-ami-hvm-.*x86_64-gp2"
  # Owner: Amazon
  owners = ["137112412989"]
}

// Create a T2 Micro EC2 instance from Amazon Linuz AMI image, with key pair
resource "aws_instance" "pizza_instance" {
  tags = {
    Owner = var.owner
  }

  ami           = data.aws_ami.latest_amazon_linux_2.id
  key_name      = aws_key_pair.generated_key.key_name
  instance_type = "t2.micro"

  subnet_id              = local.instance_subnet_id
  vpc_security_group_ids = [aws_security_group.pizza_security.id]

  lifecycle {
    ignore_changes = [subnet_id]
  }
}

// Allow traffic on port 3000 from Load Balancer (& target group) security group
resource "aws_security_group" "pizza_security" {
  name                   = "pizza-ec2-sg"
  description            = "Security group for pizza EC2 instances"
  vpc_id                 = aws_vpc.pizza_vpc.id
  revoke_rules_on_delete = true

  ingress {
    description = "Allow inbound traffic on port 3000 from my IP address and instances in Load Balancer Security group"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_address]
    // specify only my IP address, "/32" indicates only that specific IP address
    // meaning no bits left to use for IP addresses
    security_groups = [aws_security_group.pizza_lb_security.id]
    // allow traffic from port 3000 on Load Balancer security group
    // this reduces the number of potential attack vectors because the vpc would allow a much larger
    // range of IP addresses whereas this would only allow only the resources in the specified
    // security group (LB) to access the EC2 instances (in the EC2 security group)
  }

  // port to enable SSH to instance
  ingress {
    description = "Allow inbound traffic via SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_address]
  }

  egress {
    description      = "Allow all outbound traffic"
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
