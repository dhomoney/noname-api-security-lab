# Create target group for noname server
resource "aws_lb_target_group" "nonameserver" {
  name     = "nnw-${var.customer_name}-ntg"
  port     = 4789
  protocol = "UDP"
  vpc_id   = aws_vpc.noname_vpc.id
  health_check {
    port     = "443"
    protocol = "HTTPS"
    path     = "/engine/health"
  }
}

# Create target group for app server
resource "aws_lb_target_group" "appserver" {
  name     = "nnw-${var.customer_name}-atg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.app_vpc.id
  health_check {
    port     = "80"
    protocol = "HTTP"
    path     = "/"
  }
}

# Create target group for mailhog
resource "aws_lb_target_group" "mailhog" {
  name     = "nnw-${var.customer_name}-mhtg"
  port     = 8025
  protocol = "HTTP"
  vpc_id   = aws_vpc.app_vpc.id
  health_check {
    port     = "8025"
    protocol = "HTTP"
    path     = "/"
  }
}

# Create target group for noname https
resource "aws_lb_target_group" "nonameserverHttps" {
  name        = "nnw-${var.customer_name}-hntg"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = aws_vpc.app_vpc.id
  target_type = "ip"
  health_check {
    port     = "443"
    protocol = "HTTPS"
    path     = "/engine/health"
  }
}

# Register noname EC2 with target group
resource "aws_lb_target_group_attachment" "nonameserver" {
  target_group_arn = aws_lb_target_group.nonameserver.arn
  target_id        = aws_instance.nonameserver.id
  port             = 4789
}

# Register app server EC2 with target group
resource "aws_lb_target_group_attachment" "appserver" {
  target_group_arn = aws_lb_target_group.appserver.arn
  target_id        = aws_instance.app_server.id
  port             = 80
}

# Register app server EC2 with target group
resource "aws_lb_target_group_attachment" "mailhog" {
  target_group_arn = aws_lb_target_group.mailhog.arn
  target_id        = aws_instance.app_server.id
  port             = 8025
}

# Register app server EC2 with target group
resource "aws_lb_target_group_attachment" "nonameserverHttps" {
  target_group_arn  = aws_lb_target_group.nonameserverHttps.arn
  availability_zone = "all"
  target_id         = "10.0.0.${random_integer.nnoctet.result}"
  port              = 443
}
