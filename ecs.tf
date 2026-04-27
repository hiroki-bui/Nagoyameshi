# 1. ECSクラスター
resource "aws_ecs_cluster" "main" {
  name = "tabelog-cluster"
}

# 2. タスク定義（設計図）
resource "aws_ecs_task_definition" "main" {
  family                   = "tabelog-task"
  cpu                      = "512"  # 0.5 vCPU
  memory                   = "1024" # 1024 MB
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "Nagoyameshi-dev-app"
      image     = "163053485036.dkr.ecr.ap-northeast-1.amazonaws.com/tabelog-repo:latest"
      essential = true
      environment = [
        {
          name  = "APP_KEY"
          value = "base64:BHUgpqmN22cyp6fF98YCaAgM8Q+uwsm0pOGNGQEU3ok="
        },
        {
          name  = "DB_CONNECTION"
          value = "mysql" # mysqlに変更
        },
        {
          name  = "DB_HOST"
          value = aws_db_instance.main.address # 作成したRDSのエンドポイントを自動取得
        },
        {
          name  = "DB_PORT"
          value = "3306"
        },
        {
          name  = "DB_DATABASE"
          value = "tabelog_db"
        },
        {
          name  = "DB_USERNAME"
          value = "admin"
        },
        {
          name  = "DB_PASSWORD"
          value = "Namu0326"
        },
        # ... その他デバッグ用設定 ...
      ]
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/tabelog-task"
          "awslogs-region"        = "ap-northeast-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# 3. ECSサービス（司令塔）
resource "aws_ecs_service" "main" {
  name            = "tabelog-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # これで、composer install が終わるまで最大5分間、ALBはタスクを殺さずに待ってくれます。
  health_check_grace_period_seconds = 300

  network_configuration {
    subnets          = [aws_subnet.public_1a.id, aws_subnet.public_1c.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "Nagoyameshi-dev-app"
    container_port   = 80
  }
}