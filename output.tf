# Outputs
output "rancher_server_public_ip" {
  value = aws_instance.rancher_server.public_ip
}

output "rancher_server_private_ip" {
  value = aws_instance.rancher_server.private_ip
}