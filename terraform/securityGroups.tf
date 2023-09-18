# Creation of Noname Server Security Group
resource "aws_security_group" "noname_security_group" {
  name        = "nnw-${var.customer_name}-nsg"
  description = "Allow inbound HTTPS traffic and outbound all "
  vpc_id      = aws_vpc.noname_vpc.id
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.app_cidr]
  }
  ingress {
    description = "Traffic mirroring"
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = [var.app_cidr]
  }
  ingress {
    from_port        = "22"
    to_port          = "22"
    protocol         = "tcp"
    cidr_blocks      = data.aws_ip_ranges.ec2_instance_connect.cidr_blocks
    ipv6_cidr_blocks = data.aws_ip_ranges.ec2_instance_connect.ipv6_cidr_blocks
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "nnw-${var.customer_name}-nsg"
  }
}

# Creation of app Security Group
resource "aws_security_group" "app_security_group" {
  name        = "nnw-${var.customer_name}-asg"
  description = "Allow inbound HTTP traffic and outbound all "
  vpc_id      = aws_vpc.app_vpc.id
  ingress {
    description     = "app"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.app_alb_security_group.id]
  }
  ingress {
    description     = "mailhog"
    from_port       = 8025
    to_port         = 8025
    protocol        = "tcp"
    security_groups = [aws_security_group.app_alb_security_group.id]
  }
  ingress {
    from_port        = "22"
    to_port          = "22"
    protocol         = "tcp"
    cidr_blocks      = data.aws_ip_ranges.ec2_instance_connect.cidr_blocks
    ipv6_cidr_blocks = data.aws_ip_ranges.ec2_instance_connect.ipv6_cidr_blocks
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "nnw-${var.customer_name}-asg"
  }
}

# Creation of app alb Security Group
resource "aws_security_group" "app_alb_security_group" {
  name        = "nnw-${var.customer_name}-albsg"
  description = "Allow inbound HTTP traffic and outbound all"
  vpc_id      = aws_vpc.app_vpc.id
  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
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
    Name = "nnw-${var.customer_name}-albsg"
  }
}
