output "Search_Server_Address" {
  value = "http://${data.azurerm_public_ips.pips.public_ips[0].ip_address}:30002"
}

output "CDU_Server_Address" {
  value = "http://${data.azurerm_public_ips.pips.public_ips[0].ip_address}:30001"
}