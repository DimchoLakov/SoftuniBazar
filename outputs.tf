output "webapp_url" {
  value = azurerm_linux_web_app.softunibazar_wa.default_hostname
}

output "webapp_ips" {
  value = azurerm_linux_web_app.softunibazar_wa.outbound_ip_addresses
}