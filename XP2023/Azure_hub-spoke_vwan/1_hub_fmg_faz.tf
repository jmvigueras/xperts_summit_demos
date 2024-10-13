#------------------------------------------------------------------
# Create FGT HUB 
# - Config cluster FGSP
# - Create FGSP instances
# - Create vNet FGT
#------------------------------------------------------------------
// Create cluster config
module "r1_hub_config" {
  source = "git::github.com/jmvigueras/modules//azure/fgt-config_v2"

  admin_cidr     = local.admin_cidr
  admin_port     = local.admin_port
  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  api_key        = trimspace(random_string.api_key.result)

  subnet_cidrs       = module.r1_hub_vnet.subnet_cidrs
  fgt-active-ni_ips  = module.r1_hub_vnet.fgt-active-ni_ips
  fgt-passive-ni_ips = module.r1_hub_vnet.fgt-passive-ni_ips

  config_fgcp = local.r1_hub_cluster_type == "fgcp" ? true : false
  config_fgsp = local.r1_hub_cluster_type == "fgsp" ? true : false
  config_hub  = true
  config_vhub = true

  hub       = local.r1_hub
  vhub_peer = module.r1_vwan.virtual_router_ips

  vpc-spoke_cidr = [local.r1_vhub_cidr, local.r1_hub_vnet_spoke_cidr, module.r1_hub_vnet.subnet_cidrs["bastion"]]
}
// Create FGT cluster as HUB-ADVPN
// (Example with a full scenario deployment with all modules)
module "r1_hub" {
  source = "git::github.com/jmvigueras/modules//azure/fgt-ha"

  prefix                   = "${local.prefix}-r1-hub"
  location                 = local.region_1
  resource_group_name      = local.r1_resource_group_name == null ? azurerm_resource_group.r1_rg[0].name : local.r1_resource_group_name
  tags                     = local.tags
  storage-account_endpoint = local.storage-account_endpoint == null ? azurerm_storage_account.r1_storageaccount[0].primary_blob_endpoint : local.storage-account_endpoint
  size                     = local.fgt_size

  admin_username = local.admin_username
  admin_password = local.admin_password

  fgt-active-ni_ids  = module.r1_hub_vnet.fgt-active-ni_ids
  fgt-passive-ni_ids = module.r1_hub_vnet.fgt-passive-ni_ids
  fgt_config_1       = module.r1_hub_config.fgt_config_1
  fgt_config_2       = module.r1_hub_config.fgt_config_2

  fgt_passive = true
}
// Module VNET for FGT
// - This module will generate VNET and network intefaces for FGT cluster
module "r1_hub_vnet" {
  source = "git::github.com/jmvigueras/modules//azure/vnet-fgt_v2"

  prefix              = "${local.prefix}-r1-hub"
  location            = local.region_1
  resource_group_name = local.r1_resource_group_name == null ? azurerm_resource_group.r1_rg[0].name : local.r1_resource_group_name
  tags                = local.tags

  vnet-fgt_cidr = local.r1_hub_vnet_cidr
  admin_port    = local.admin_port
  admin_cidr    = local.admin_cidr

  accelerate = true
  config_xlb = true
}
#------------------------------------------------------------------
# Create HUB LB in Region 1 
#------------------------------------------------------------------
module "r1_xlb" {
  depends_on = [module.r1_hub_vnet]
  source     = "git::github.com/jmvigueras/modules//azure/xlb"

  prefix              = "${local.prefix}-r1-hub"
  location            = local.region_1
  resource_group_name = local.r1_resource_group_name == null ? azurerm_resource_group.r1_rg[0].name : local.r1_resource_group_name
  tags                = local.tags

  config_gwlb        = local.config_gwlb
  ilb_ip             = local.r1_ilb_ip
  backend-probe_port = local.backend-probe_port

  vnet-fgt           = module.r1_hub_vnet.vnet
  subnet_ids         = module.r1_hub_vnet.subnet_ids
  subnet_cidrs       = module.r1_hub_vnet.subnet_cidrs
  fgt-active-ni_ips  = module.r1_hub_vnet.fgt-active-ni_ips
  fgt-passive-ni_ips = module.r1_hub_vnet.fgt-passive-ni_ips
}
#------------------------------------------------------------------
# Create vnet spoke peered to FGT VNET
#------------------------------------------------------------------
module "r1_hub_vnet_spoke" {
  source     = "git::github.com/jmvigueras/modules//azure/vnet-spoke_v2"

  prefix              = "${local.prefix}-r1-hub-vnet-spoke"
  location            = local.region_1
  resource_group_name = local.r1_resource_group_name == null ? azurerm_resource_group.r1_rg[0].name : local.r1_resource_group_name
  tags                = local.tags

  vnet_spoke_cidr = local.r1_hub_vnet_spoke_cidr
  vnet_fgt        = module.r1_hub_vnet.vnet
}
// Create VM in vNet spoke
module "r1_hub_vnet_spoke_vm" {
  source = "git::github.com/jmvigueras/modules//azure/new-vm_rsa-ssh_v2"

  prefix                   = "${local.prefix}-r1-hub-vnet-spoke"
  location                 = local.region_1
  resource_group_name      = local.r1_resource_group_name == null ? azurerm_resource_group.r1_rg[0].name : local.r1_resource_group_name
  tags                     = local.tags
  storage-account_endpoint = local.storage-account_endpoint == null ? azurerm_storage_account.r1_storageaccount[0].primary_blob_endpoint : local.storage-account_endpoint
  admin_username           = local.admin_username
  rsa-public-key           = trimspace(tls_private_key.ssh.public_key_openssh)

  subnet_id   = module.r1_hub_vnet_spoke.subnet_ids["subnet_1"]
  subnet_cidr = module.r1_hub_vnet_spoke.subnet_cidrs["subnet_1"]
}
#--------------------------------------------------------------------------------
# Create UDR in vNet spoke subnet 1 and 2 to iLB
#--------------------------------------------------------------------------------
// Route-table definition
resource "azurerm_route_table" "r1_hub_vnet_spoke_rt" {
  name                = "${local.prefix}-r1-hub-vnet-spoke-rt"
  location            = local.region_1
  resource_group_name = local.r1_resource_group_name == null ? azurerm_resource_group.r1_rg[0].name : local.r1_resource_group_name

  disable_bgp_route_propagation = false

  route {
    name                   = "default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = local.r1_ilb_ip
  }
  route {
    name           = "admin-cdir"
    address_prefix = local.admin_cidr
    next_hop_type  = "Internet"
  }
}
// Route table association
resource "azurerm_subnet_route_table_association" "r1_hub_vnet_spoke_rta_subnet_1" {
  subnet_id      = module.r1_hub_vnet_spoke.subnet_ids["subnet_1"]
  route_table_id = azurerm_route_table.r1_hub_vnet_spoke_rt.id
}
// Route table association
resource "azurerm_subnet_route_table_association" "r1_hub_vnet_spoke_rta_subnet_2" {
  subnet_id      = module.r1_hub_vnet_spoke.subnet_ids["subnet_2"]
  route_table_id = azurerm_route_table.r1_hub_vnet_spoke_rt.id
}
#------------------------------------------------------------------------------
# Create FAZ and FMG
#------------------------------------------------------------------------------
// Create FAZ instances
module "faz" {
  source = "git::github.com/jmvigueras/modules//azure/faz"

  prefix                   = local.prefix
  location                 = local.region_1
  resource_group_name      = local.r1_resource_group_name == null ? azurerm_resource_group.r1_rg[0].name : local.r1_resource_group_name
  tags                     = local.tags
  storage-account_endpoint = local.storage-account_endpoint == null ? azurerm_storage_account.r1_storageaccount[0].primary_blob_endpoint : local.storage-account_endpoint
  size                     = local.fmg-faz_size


  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  api_key        = trimspace(random_string.api_key.result)
  license_type   = local.faz_license_type
  license_file   = local.faz_license_file

  admin_username = local.admin_username
  admin_password = local.admin_password

  subnet_ids = {
    public  = module.r1_hub_vnet.subnet_ids["public"]
    private = module.r1_hub_vnet.subnet_ids["bastion"]
  }
  subnet_cidrs = {
    public  = module.r1_hub_vnet.subnet_cidrs["public"]
    private = module.r1_hub_vnet.subnet_cidrs["bastion"]
  }
}
// Create FMG instances
module "fmg" {
  source = "git::github.com/jmvigueras/modules//azure/fmg"

  prefix                   = local.prefix
  location                 = local.region_1
  resource_group_name      = local.r1_resource_group_name == null ? azurerm_resource_group.r1_rg[0].name : local.r1_resource_group_name
  tags                     = local.tags
  storage-account_endpoint = local.storage-account_endpoint == null ? azurerm_storage_account.r1_storageaccount[0].primary_blob_endpoint : local.storage-account_endpoint
  size                     = local.fmg-faz_size

  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  api_key        = trimspace(random_string.api_key.result)
  license_type   = local.fmg_license_type
  license_file   = local.fmg_license_file

  admin_username = local.admin_username
  admin_password = local.admin_password

  subnet_ids = {
    public  = module.r1_hub_vnet.subnet_ids["public"]
    private = module.r1_hub_vnet.subnet_ids["bastion"]
  }
  subnet_cidrs = {
    public  = module.r1_hub_vnet.subnet_cidrs["public"]
    private = module.r1_hub_vnet.subnet_cidrs["bastion"]
  }
}