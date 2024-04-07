# output "web_link" {
#   value       = "http://${aws_instance.example.public_ip}:${var.server_port}"
#   description = "The public IP address of the web server."
# }

output "alb_dns_name" {
  value       = aws_lb.example.dns_name
  description = "The domain name of the load balancer."
}