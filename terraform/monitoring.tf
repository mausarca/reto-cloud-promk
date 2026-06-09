# Grupo de Logs Centralizado para las Aplicaciones
resource "aws_cloudwatch_log_group" "apps_log_group" {
  name              = "/aws/ec2/casino-apps-${local.suffix}"
  retention_in_days = 30
  tags              = { Environment = var.operacion }
}

# Bucket S3 dedicado en exclusividad a almacenar los logs del ALB
resource "aws_s3_bucket" "alb_logs" {
  bucket        = "s3-alb-logs-${local.suffix}"
  force_destroy = true
}
