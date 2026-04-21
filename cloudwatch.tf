resource "aws_cloudwatch_log_group" "ecs_log" {
  name              = "/ecs/tabelog-task"
  retention_in_days = 7
}