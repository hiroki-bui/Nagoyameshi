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
      name      = "tabelog-container"
      image     = "163053485036.dkr.ecr.ap-northeast-1.amazonaws.com/tabelog-repo:latest"
      essential = true

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
    container_name   = "tabelog-container"
    container_port   = 80
  }
}