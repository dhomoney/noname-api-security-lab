# Create IPv4 IP Set
resource "aws_wafv2_ip_set" "ipv4" {
  name               = "${var.customer_name}-IPv4Set"
  description        = "Noname ipv4 block set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = []
}

# Create IPv6 IP Set
resource "aws_wafv2_ip_set" "ipv6" {
  name               = "${var.customer_name}-IPv6Set"
  description        = "Noname ipv6 block set"
  scope              = "REGIONAL"
  ip_address_version = "IPV6"
  addresses          = []
}

# Create ACL rule group for prevention
resource "aws_wafv2_rule_group" "prevention" {
  name        = "${var.customer_name}-PreventionRuleGroup"
  description = "Noname prevention rule group"
  scope       = "REGIONAL"
  capacity    = 1000

  visibility_config {
    cloudwatch_metrics_enabled = false
    sampled_requests_enabled   = false
    metric_name                = "${var.customer_name}-PreventionRuleGroup-Metric"
  }

  rule {
    name     = "${var.customer_name}IPv4PreventionRule"
    priority = 1
    action {
      block {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "${var.customer_name}IPv4PreventionRule-Metric"
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.ipv4.arn
      }
    }
  }

  rule {
    name     = "${var.customer_name}IPv6PreventionRule"
    priority = 2
    action {
      block {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "${var.customer_name}IPv6PreventionRule-Metric"
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.ipv6.arn
      }
    }
  }
}

# Create app server waf
resource "aws_wafv2_web_acl" "appserver" {
  name  = "${var.customer_name}-workshop-app-waf"
  scope = "REGIONAL"
  default_action {
    allow {}
  }
  visibility_config {
    cloudwatch_metrics_enabled = false
    sampled_requests_enabled   = false
    metric_name                = "${var.customer_name}-workshop-app-waf-Metric"
  }

  rule {
    name     = "${var.customer_name}AlwaysAllowNoname"
    priority = 0
    action {
      allow {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "${var.customer_name}AlwaysAllowNoname"
    }

    statement {
      byte_match_statement {
        positional_constraint = "CONTAINS"
        search_string         = "${var.customer_name}.nnsworkshop.com"
        text_transformation {
          priority = 0
          type     = "NONE"
        }
        field_to_match {
          single_header {
            name = "host"
          }
        }
      }
    }
  }

  rule {
    name     = "${var.customer_name}PreventionRuleGroup"
    priority = 1
    statement {
      rule_group_reference_statement {
        arn = aws_wafv2_rule_group.prevention.arn
      }
    }
    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      sampled_requests_enabled   = false
      metric_name                = "${var.customer_name}PreventionRuleGroup-Metric"
    }
  }
}

# Associate waf
resource "aws_wafv2_web_acl_association" "appserver" {
  resource_arn = aws_lb.appserver.arn
  web_acl_arn  = aws_wafv2_web_acl.appserver.arn
}