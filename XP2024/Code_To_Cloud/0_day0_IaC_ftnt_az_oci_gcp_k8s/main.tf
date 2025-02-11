#--------------------------------------------------------------------------
# Necessary variables if not provided
#--------------------------------------------------------------------------
# GCP user info
data "google_client_openid_userinfo" "me" {}
# Create private key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "local_file" "ssh_private_key_pem" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "./ssh-key/${local.prefix}-ssh-key.pem"
  file_permission = "0600"
}
# Get my public IP
data "http" "my-public-ip" {
  url = "http://ifconfig.me/ip"
}
# Create new random API key to be provisioned in FortiGates.
resource "random_string" "api_key" {
  length  = 30
  special = false
  numeric = true
}
# Create new random API key to be provisioned in FortiGates.
resource "random_string" "vpn_psk" {
  length  = 30
  special = false
  numeric = true
}
# Create new random password for Redis DB
resource "random_string" "db_pass" {
  length  = 20
  special = false
  numeric = true
}
// Create storage account if not provided
resource "random_id" "randomId" {
  count       = local.azure_storage-account_endpoint == null ? 1 : 0
  byte_length = 8
}
resource "azurerm_storage_account" "storageaccount" {
  count                    = local.azure_storage-account_endpoint == null ? 1 : 0
  name                     = "stgra${random_id.randomId[count.index].hex}"
  resource_group_name      = local.azure_resource_group_name == null ? azurerm_resource_group.rg[0].name : local.azure_resource_group_name
  location                 = local.azure_location
  account_replication_type = "LRS"
  account_tier             = "Standard"
  min_tls_version          = "TLS1_2"

  tags = local.tags
}
// Create Resource Group if it is null
resource "azurerm_resource_group" "rg" {
  count    = local.azure_resource_group_name == null ? 1 : 0
  name     = "${local.prefix}-rg"
  location = local.azure_location

  tags = local.tags
}