module "tags" {
  source  = "rhythmictech/tags/terraform"
  version = "0.0.2"

  enforce_case = "UPPER"
  tags         = var.tags
}

provider "azurerm" {
  version = ">=1.40.0"
}

resource "azurerm_postgresql_server" "server" {
  name                = lower(var.server_name)
  location            = var.location
  resource_group_name = var.resource_group_name

  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_password
  sku_name                     = var.sku_name
  ssl_enforcement              = var.ssl_enforcement
  version                      = var.server_version

  storage_profile {
    auto_grow             = var.storage_autogrow
    backup_retention_days = var.backup_retention_days
    geo_redundant_backup  = var.geo_redundant_backup
    storage_mb            = var.storage_mb
  }

  tags = module.tags.tags
}

resource "azurerm_postgresql_database" "database" {
  for_each            = var.dbs

  charset             = lookup(each.value, "charset", "UTF8")
  collation           = lookup(each.value, "collation", "en_US.utf8")
  name                = each.value.name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.server.name
}

resource "azurerm_postgresql_firewall_rule" "firewall_rule" {
  for_each            = var.firewall_rules

  name                = each.key
  start_ip_address    = each.value.start_ip
  end_ip_address      = each.value.end_ip
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.server.name
}

resource "azurerm_postgresql_virtual_network_rule" "vnet_rule" {
  for_each            = var.vnet_rules

  name                = each.key
  subnet_id           = each.value
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.server.name
}

resource "azurerm_postgresql_configuration" "config" {
  for_each            = var.postgresql_configurations

  name                = each.key
  value               = each.value
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.server.name
}
