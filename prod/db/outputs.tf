output "address" {
  value       = aws_instance.database.private_ip
  description = "Connect to the database at this endpoint."
}