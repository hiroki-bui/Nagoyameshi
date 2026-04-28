# #1. バージニア北部用のプロバイダー（CloudFront用証明書に必須）
# provider "aws" {
#   alias  = "virginia"
#   region = "us-east-1"
# }

# # 2. ACM証明書 (バージニア北部)
# resource "aws_acm_certificate" "virginia" {
#   provider          = aws.virginia
#   domain_name       = "samurai-kadai.com" # お使いのドメイン名
#   validation_method = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# # 3. DNS検証用レコード (Route 53)
# # これにより、ACMの検証が自動で行われます
# resource "aws_route53_record" "cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.virginia.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = aws_route53_zone.main.id # 既存のホストゾーンIDリソース名
# }

# # 4. 証明書の検証完了を待機
# resource "aws_acm_certificate_validation" "virginia" {
#   provider                = aws.virginia
#   certificate_arn         = aws_acm_certificate.virginia.arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
# }

# # 5. CloudFront Distribution (WAFなし)
# resource "aws_cloudfront_distribution" "main" {
#   origin {
#     domain_name = aws_lb.main.dns_name # ALBのリソース名に合わせてください
#     origin_id   = "ALB-Origin"

#     custom_origin_config {
#       http_port              = 80
#       https_port             = 443
#       origin_protocol_policy = "http-only" # ALBがHTTP(80)で受けている場合
#       origin_ssl_protocols   = ["TLSv1.2"]
#     }
#   }

#   enabled         = true
#   is_ipv6_enabled = true
#   comment         = "Nagoyameshi CloudFront"
#   aliases         = ["samurai-kadai.com"] # ドメイン名

#   default_cache_behavior {
#     allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
#     cached_methods   = ["GET", "HEAD"]
#     target_origin_id = "ALB-Origin"

#     # Laravelでセッションやクエリを維持するための設定
#     forwarded_values {
#       query_string = true
#       headers      = ["Host", "Authorization"] 
#       cookies {
#         forward = "all"
#       }
#     }

#     viewer_protocol_policy = "redirect-to-https"
#     min_ttl                = 0
#     default_ttl            = 3600
#     max_ttl                = 86400
#   }

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }

#   viewer_certificate {
#     acm_certificate_arn      = aws_acm_certificate_validation.virginia.certificate_arn
#     ssl_support_method       = "sni-only"
#     minimum_protocol_version = "TLSv1.2_2021"
#   }
# }

# # 6. Route 53 Aレコード (ドメインをCloudFrontに向ける)
# resource "aws_route53_record" "cloudfront_alias" {
#   zone_id = aws_route53_zone.main.id
#   name    = "samurai-kadai.com"
#   type    = "A"

#   alias {
#     name                   = aws_cloudfront_distribution.main.domain_name
#     zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
#     evaluate_target_health = false
#   }
# }