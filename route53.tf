# Route 53 パブリックホストゾーンの作成
resource "aws_route53_zone" "main" {
  name = "samurai-kadai.com"

  tags = {
    Name = "tabelog-host-zone"
  }
}

# 作成したホストゾーンのIDを他のファイルでも使いやすくするための出力設定
output "hosted_zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "name_servers" {
  value = aws_route53_zone.main.name_servers
}

# ドメイン名でALBにアクセスするための設定
resource "aws_route53_record" "alb_alias" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "samurai-kadai.com" # または www.samurai-kadai.com
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}