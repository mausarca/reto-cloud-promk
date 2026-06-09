output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "Dirección DNS pública del Balanceador de Carga"
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.cdn.domain_name
  description = "URL asignada por CloudFront para acceder a los assets estáticos"
}

output "vpc_principal_id" {
  value       = aws_vpc.principal.id
  description = "ID de la VPC Principal"
}

output "vpc_secundaria_id" {
  value       = aws_vpc.secundaria.id
  description = "ID de la VPC Secundaria de Datos Históricos"
}

output "redis_primary_endpoint" {
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
  description = "Endpoint primario para la conexión de caché Redis"
}