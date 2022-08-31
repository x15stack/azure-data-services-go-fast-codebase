output "ixup_encryption_gateway_id" {
  value = azurerm_windows_virtual_machine.ixup_egw[*].id
}

output "ixup_encryption_gateway_ip" {
  value = azurerm_windows_virtual_machine.ixup_egw[*].private_ip_address
}