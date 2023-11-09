

// Route53 Record
# resource "aws_route53_record" "bastion" {
#   zone_id = var.route53_zone_id
#   name    = "secure"
#   type    = "A"
#   ttl     = "300"
#   records = [aws_instance.bastion.public_ip]
# }


