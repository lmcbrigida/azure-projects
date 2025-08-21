terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.114"
    }
  }
}

provider "azurerm" {
  features {}
}

# ----------------------------
# Storage Account + Static Website
# ----------------------------
resource "azurerm_storage_account" "sa" {
  name                     = lower("${var.prefix}sa${substr(replace(uuid(), "-", ""), 0, 6)}")
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  static_website {
    index_document     = "index.html"
    error_404_document = "index.html"
  }
}

resource "azurerm_storage_blob" "index" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "${path.module}/site/index.html"

  content_type = "text/html"
}

# ----------------------------
# Front Door Standard
# ----------------------------
resource "azurerm_cdn_frontdoor_profile" "fd" {
  name                = "${var.prefix}-fdprof"
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  name                     = "${var.prefix}-fdendpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id
}

resource "azurerm_cdn_frontdoor_origin_group" "og" {
  name                     = "${var.prefix}-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id
  session_affinity_enabled = false

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 4
    successful_samples_required        = 2
  }
}

resource "azurerm_cdn_frontdoor_origin" "origin" {
  name                          = "${var.prefix}-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.og.id
  enabled                       = true

  certificate_name_check_enabled = false

  host_name          = azurerm_storage_account.sa.primary_web_host
  origin_host_header = azurerm_storage_account.sa.primary_web_host

  http_port  = 80
  https_port = 443
}

resource "azurerm_cdn_frontdoor_route" "route" {
  name                          = "${var.prefix}-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.og.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.origin.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  https_redirect_enabled = true
  forwarding_protocol    = "HttpsOnly"
}
