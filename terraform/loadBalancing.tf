# Create NLB for traffic mirroring session
resource "aws_lb" "noname" {
  name               = "nnw-${var.customer_name}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = [aws_subnet.noname_subnet.id]

  tags = {
    Name = "nnw-${var.customer_name}-nlb"
  }
}

# Create ALB for app server
resource "aws_lb" "appserver" {
  name               = "nnw-${var.customer_name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.app_subnet1.id, aws_subnet.app_subnet2.id]
  security_groups    = [aws_security_group.app_alb_security_group.id]

  tags = {
    Name = "nnw-${var.customer_name}-alb"
  }
}

# Create the NLB listener for traffic mirroring session
resource "aws_lb_listener" "trafficmirroring" {
  load_balancer_arn = aws_lb.noname.arn
  port              = "4789"
  protocol          = "UDP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nonameserver.arn
  }
}

# Create the ALB listener for app server
resource "aws_lb_listener" "app_server_alb" {
  load_balancer_arn = aws_lb.appserver.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.workshop.arn
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "502"
    }
  }
}

# Create HTTPS listener for crapi
resource "aws_lb_listener_rule" "crapi_https" {
  listener_arn = aws_lb_listener.app_server_alb.arn
  priority     = 3
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.appserver.arn
  }
  condition {
    host_header {
      values = ["${var.customer_name}-crapi.nnsworkshop.com"]
    }
  }
}

# Create HTTPS listener to block engine access
resource "aws_lb_listener_rule" "block_engine" {
  listener_arn = aws_lb_listener.app_server_alb.arn
  priority     = 1
  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "403"
    }
  }
  condition {
    path_pattern {
      values = ["/engine*"]
    }
  }
}

# Create HTTPS listener for mailhog
resource "aws_lb_listener_rule" "mailhog_https" {
  listener_arn = aws_lb_listener.app_server_alb.arn
  priority     = 4
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mailhog.arn
  }
  condition {
    host_header {
      values = ["${var.customer_name}-mailhog.nnsworkshop.com"]
    }
  }
}

# Create HTTPS listener for noname server
resource "aws_lb_listener_rule" "nonameserver_https" {
  listener_arn = aws_lb_listener.app_server_alb.arn
  priority     = 2
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nonameserverHttps.arn
  }
  condition {
    host_header {
      values = ["${var.customer_name}.nnsworkshop.com"]
    }
  }
}