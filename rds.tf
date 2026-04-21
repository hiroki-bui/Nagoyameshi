# RDS用のサブネットグループ（DBを置く場所の定義）
resource "aws_db_subnet_group" "main" {
  name       = "tabelog-db-subnet-group"
  subnet_ids = [aws_subnet.private_1a.id, aws_subnet.private_1c.id] # プライベートサブネットに配置

  tags = {
    Name = "tabelog-db-subnet-group"
  }
}

# RDSインスタンス本体
resource "aws_db_instance" "main" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro" # 無料枠対象のサイズ
  db_name                = "tabelog_db"  # データベース名
  username               = "admin"
  password               = "Namu0326"
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true # 削除時にバックアップを取らない（学習用）
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  tags = {
    Name = "tabelog-db"
  }
}