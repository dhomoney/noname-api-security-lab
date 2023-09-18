# Create mirroring filter
resource "aws_ec2_traffic_mirror_filter" "filter" {
  description      = "${var.customer_name}-workshop-filter"
  network_services = ["amazon-dns"]
  tags = {
    Name = "${var.customer_name}-workshop-filter"
  }
}

# Create filter rules (in)
resource "aws_ec2_traffic_mirror_filter_rule" "rulein" {
  description              = "allow in"
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.filter.id
  destination_cidr_block   = "0.0.0.0/0"
  source_cidr_block        = "0.0.0.0/0"
  rule_action              = "accept"
  rule_number              = 1
  traffic_direction        = "ingress"
  protocol                 = 6
}

# Create filter rules (out)
resource "aws_ec2_traffic_mirror_filter_rule" "ruleout" {
  description              = "allow out"
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.filter.id
  destination_cidr_block   = "0.0.0.0/0"
  source_cidr_block        = "0.0.0.0/0"
  rule_action              = "accept"
  rule_number              = 1
  traffic_direction        = "egress"
  protocol                 = 6
}

# Create mirroring target
resource "aws_ec2_traffic_mirror_target" "noname" {
  description               = "${var.customer_name}-workshop-tnlb"
  network_load_balancer_arn = aws_lb.noname.arn
  tags = {
    Name = "${var.customer_name}-workshop-tnlb"
  }
}

# Create mirroring session
resource "aws_ec2_traffic_mirror_session" "session" {
  description              = "${var.customer_name}-workshop-tms"
  network_interface_id     = aws_instance.app_server.primary_network_interface_id
  session_number           = 1
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.filter.id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.noname.id
  virtual_network_id       = 131073 # set the VXLAN ID so that Noname properly identifies the source
  tags = {
    Name = "${var.customer_name}-workshop-tms"
  }
}