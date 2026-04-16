#------------------------------
# ALB
#------------------------------
# ALB本体の設定
resource "aws_lb" "main" {
  name               = "tabelog-alb"
  internal           = false # インターネット公開用
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1a.id, aws_subnet.public_1c.id]

  tags = { Name = "tabelog-alb" }
}

# ターゲットグループ（ALBが通信を飛ばす先の「箱」）
resource "aws_lb_target_group" "main" {
  name        = "tabelog-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Fargateの場合は "ip" を指定

  health_check {
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

# リスナー（ALBが待ち受けるポートの設定）
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}