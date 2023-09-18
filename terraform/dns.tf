# Create crapi DNS record for ALB
resource "aws_route53_record" "crapi_dns" {
  zone_id = data.aws_route53_zone.workshop.id
  name    = "${var.customer_name}-crapi"
  type    = "CNAME"
  ttl     = "5"

  weighted_routing_policy {
    weight = 10
  }

  set_identifier = "${var.customer_name}-crapi"
  records        = [aws_lb.appserver.dns_name]
}

# Create mailhog DNS record for ALB
resource "aws_route53_record" "mailhog_dns" {
  zone_id = data.aws_route53_zone.workshop.id
  name    = "${var.customer_name}-mailhog"
  type    = "CNAME"
  ttl     = "5"

  weighted_routing_policy {
    weight = 10
  }

  set_identifier = "${var.customer_name}-mailhog"
  records        = [aws_lb.appserver.dns_name]
}

# Create mailhog DNS record for Noname server
resource "aws_route53_record" "noname_dns" {
  zone_id = data.aws_route53_zone.workshop.id
  name    = var.customer_name
  type    = "CNAME"
  ttl     = "5"

  weighted_routing_policy {
    weight = 10
  }

  set_identifier = "${var.customer_name}-noname"
  records        = [aws_lb.appserver.dns_name]
}
