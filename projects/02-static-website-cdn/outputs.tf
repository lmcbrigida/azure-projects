output "storage_static_website_url" {
  value = azurerm_storage_account.sa.primary_web_endpoint
}

output "frontdoor_url" {
  value = "https://${azurerm_cdn_frontdoor_endpoint.endpoint.host_name}/"
}
