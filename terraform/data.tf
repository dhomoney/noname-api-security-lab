# Current aws region
data "aws_region" "current" {}

# Random octet
resource "random_integer" "nnoctet" {
  min = 4
  max = 253
}
resource "random_integer" "appoctet" {
  min = 4
  max = 253
}

# Get the IP range for the EC2_INSTANCE_CONNECT
data "aws_ip_ranges" "ec2_instance_connect" {
  regions  = [data.aws_region.current.name]
  services = ["ec2_instance_connect"]
}

# Get the certificate for workshop
data "aws_acm_certificate" "workshop" {
  domain   = "*.nnsworkshop.com"
  statuses = ["ISSUED"]
}

# Route 53 zone
data "aws_route53_zone" "workshop" {
  name         = "nnsworkshop.com."
  private_zone = false
}

# Gets available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Random password used when setting up noname-su
resource "random_password" "noname_su" {
  length           = 16
  special          = false
}

# Random password used when setting up noname-admin
resource "random_password" "noname_admin" {
  length           = 16
  special          = true
  override_special = "@"
  min_special      = 1
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
}

# Grab the AMI for the latest Ubuntu 20
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Get the current AWS account ID
data "aws_caller_identity" "current" {}

data "aws_network_interfaces" "app_alb_network_interfaces" {
  filter {
    name = "description"
    # Assumes the description has not been manually modified
    values = ["ELB ${resource.aws_lb.appserver.arn_suffix}"]
  }
}

data "aws_network_interface" "app_alb_network_interface" {
  id = tolist(data.aws_network_interfaces.app_alb_network_interfaces.ids)[0]
}
