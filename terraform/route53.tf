variable "domain" {
  description = "Route 53 で管理しているドメイン名"
  type        = string

  #FIXME:
  default = "f-saito.link"
}

# Route53 Hosted Zone
# https://www.terraform.io/docs/providers/aws/d/route53_zone.html
data "aws_route53_zone" "main" {
  name         = "${var.domain}"
  private_zone = false
}

# ACM
# https://www.terraform.io/docs/providers/aws/r/acm_certificate.html
resource "aws_acm_certificate" "main" {
  domain_name = "${var.domain}"

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Route53 record
# https://www.terraform.io/docs/providers/aws/r/route53_record.html
resource "aws_route53_record" "validation" {
  depends_on = ["aws_acm_certificate.main"]

  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = "${data.aws_route53_zone.main.id}"

  ttl = 60

  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type
}

# ACM Validate
# https://www.terraform.io/docs/providers/aws/r/acm_certificate_validation.html
resource "aws_acm_certificate_validation" "main" {
  certificate_arn = "${aws_acm_certificate.main.arn}"

  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

# Route53 record
# https://www.terraform.io/docs/providers/aws/r/route53_record.html
resource "aws_route53_record" "main" {
  type = "A"

  name    = "${var.domain}"
  zone_id = "${data.aws_route53_zone.main.id}"

  alias {
    name                   = "${aws_lb.main.dns_name}"
    zone_id                = "${aws_lb.main.zone_id}"
    evaluate_target_health = true
  }
}
