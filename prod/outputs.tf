output "alb_dns_name" {
  value       = aws_lb.server.dns_name
  description = "The domain name of the load balancer."
}

