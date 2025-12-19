output "load_balancer_dns" {
  description = "URL pública del Balanceador de Carga"
  value       = aws_lb.app_lb.dns_name
}
