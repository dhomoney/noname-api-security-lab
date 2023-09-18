# Output noname server IP address
output "urls" {
  value       = "https://${var.customer_name}.nnsworkshop.com https://${var.customer_name}-crapi.nnsworkshop.com https://${var.customer_name}-mailhog.nnsworkshop.com"
  description = "URLS:"
}

# Output noname-su password
output "noname_su_password" {
  value       = random_password.noname_su.result
  description = "noname-su password:"
  sensitive   = true
}

# Output noname-admin password
output "noname_admin_password" {
  value       = random_password.noname_admin.result
  description = "noname-admin password:"
  sensitive   = true
}