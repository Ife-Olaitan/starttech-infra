# CloudWatch Log Group for backend application logs
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/app/${var.name}/backend"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.name}-backend-logs"
  }
}

# SNS Topic for alarm notifications
resource "aws_sns_topic" "alerts" {
  name = "${var.name}-alerts"
}