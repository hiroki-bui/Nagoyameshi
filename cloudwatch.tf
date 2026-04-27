resource "aws_cloudwatch_log_group" "ecs_log" {
  name              = "/ecs/Nagoyameshi-dev-app"
  retention_in_days = 7
}