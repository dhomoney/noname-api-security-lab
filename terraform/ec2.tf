# Create the EC2 instance and install Noname
resource "aws_instance" "nonameserver" {
  depends_on           = [aws_internet_gateway.noname_gw]
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.nnServer_machine_type
  subnet_id            = aws_subnet.noname_subnet.id
  availability_zone    = data.aws_availability_zones.available.names[0]
  iam_instance_profile = aws_iam_instance_profile.noname_server_profile.name
  private_ip           = "10.0.0.${random_integer.nnoctet.result}"
  root_block_device {
    encrypted = true
    tags = {
      name = "nnw-${var.customer_name}-nvol"
    }
    volume_size = "300"
    volume_type = "gp2"
  }
  security_groups = [
    aws_security_group.noname_security_group.id
  ]
  source_dest_check = "false"
  tags = {
    Name = "nnw-${var.customer_name}-nn"
  }
  user_data = templatefile("${path.module}/scripts/nn-bootstrap.sh", {
    noname_version : var.noname_version,
    aws_tmt : aws_ec2_traffic_mirror_target.noname.id,
    aws_region : data.aws_region.current.name,
    aws_account : data.aws_caller_identity.current.account_id,
    aws_vpc_id : aws_vpc.noname_vpc.id,
    aws_subnet_id : aws_subnet.noname_subnet.id,
    app_server_id : aws_instance.app_server.id,
    app_server_ip : "${var.customer_name}-crapi.nnsworkshop.com",
    noname_su_password : random_password.noname_su.result,
    noname_admin_password : random_password.noname_admin.result,
    ipv4_arn : aws_wafv2_ip_set.ipv4.arn,
    ipv4_id : aws_wafv2_ip_set.ipv4.id,
    ipv6_arn : aws_wafv2_ip_set.ipv6.arn,
    ipv6_id : aws_wafv2_ip_set.ipv6.id,
    waf_rulegroup_arn : aws_wafv2_rule_group.prevention.arn,
    waf_rulegroup_id : aws_wafv2_rule_group.prevention.id,
    alb_arn : aws_lb.appserver.arn,
    customer_name : var.customer_name,
    email_csv : var.participant_emails,
    crapi_private_ip : "${data.aws_network_interface.app_alb_network_interface.private_ip}",
    git_branch : var.git_branch,
    slack_userid : var.slack_userid,
    slack_channelid : var.slack_channelid,
    callback_host : var.callback_host,
    package_stage : var.package_stage
  })
}

# Create the EC2 instance and install app
resource "aws_instance" "app_server" {
  depends_on           = [aws_internet_gateway.app_gw]
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.app_machine_type
  subnet_id            = aws_subnet.app_subnet1.id
  availability_zone    = data.aws_availability_zones.available.names[0]
  iam_instance_profile = aws_iam_instance_profile.noname_server_profile.name
  private_ip           = "10.1.0.${random_integer.appoctet.result}"
  root_block_device {
    encrypted = true
    tags = {
      name = "nnw-${var.customer_name}-avol"
    }
    volume_size = "300"
    volume_type = "gp2"
  }
  security_groups = [
    aws_security_group.app_security_group.id
  ]
  source_dest_check = "false"
  tags = {
    Name = "nnw-${var.customer_name}-app"
  }
  user_data = templatefile("${path.module}/scripts/crapi-bootstrap.sh", {
    git_branch : var.git_branch
  })
}
