#------------------------------------
# Security Group 
#------------------------------------
# ALB用のセキュリティグループ（インターネットからのHTTPアクセスを許可）
resource "aws_security_group" "alb_sg" {
  name        = "tabelog-alb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "tabelog-alb-sg" }
}

# ECS用のセキュリティグループ（ALBからの通信のみ許可）
resource "aws_security_group" "ecs_sg" {
  name        = "tabelog-ecs-sg"
  description = "Allow traffic only from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    # ALBのセキュリティグループIDをソースに指定することで、ALB経由以外の通信を遮断
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "tabelog-ecs-sg" }
}