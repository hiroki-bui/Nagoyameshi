# ECSタスク実行ロール（FargateがAWSリソースを操作するためのロール）
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "tabelog-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# AWS管理のポリシー（AmazonECSTaskExecutionRolePolicy）をロールに紐付け
# これにより、ECRからのプルやログ出力の権限が付与されます
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}