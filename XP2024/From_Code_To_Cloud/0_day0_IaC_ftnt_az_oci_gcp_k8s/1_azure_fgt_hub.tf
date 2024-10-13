#------------------------------------------------------------------
# Create FGT 
# - Create cluster FGCP config
# - Create FGCP instances
# - Create vNet
# - Create LB
#------------------------------------------------------------------
// VNET for FGT
module "azure_fgt_vnet" {
  source = "git::github.com/jmvigueras/modules//azure/vnet-fgt_v2"

  prefix              = local.prefix
  location            = local.azure_location
  resource_group_name = local.azure_resource_group_name == null ? azurerm_resource_group.rg[0].name : local.azure_resource_group_name
  tags                = local.tags

  vnet-fgt_cidr = local.fgt_cidrs["azure"]
  admin_cidr    = local.fgt_admin_cidr
  admin_port    = local.fgt_admin_port

  config_xlb = true
}
// FGT config
module "azure_fgt_config" {
  source = "git::github.com/jmvigueras/modules//azure/fgt-config_v2"

  admin_cidr     = local.fgt_admin_cidr
  admin_port     = local.fgt_admin_port
  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  api_key        = trimspace(random_string.api_key.result)

  //license_type   = local.fgt_license_type
  //license_file_1 = "./licenses/licenseFGT1.lic" 

  fgt_active_extra-config = join("\n",
    [for config in data.template_file.azure_fgt_1_extra_config : config.rendered]
  )
  fgt_passive_extra-config = join("\n",
    [for config in data.template_file.azure_fgt_2_extra_config : config.rendered]
  )

  subnet_cidrs       = module.azure_fgt_vnet.subnet_cidrs
  fgt-active-ni_ips  = module.azure_fgt_vnet.fgt-active-ni_ips
  fgt-passive-ni_ips = module.azure_fgt_vnet.fgt-passive-ni_ips

  # Config for SDN connector
  # - API calls
  subscription_id     = var.subscription_id
  client_id           = var.client_id
  client_secret       = var.client_secret
  tenant_id           = var.tenant_id
  resource_group_name = local.azure_resource_group_name == null ? azurerm_resource_group.rg[0].name : local.azure_resource_group_name

  config_fgcp = true
  config_xlb  = true

  config_hub = true
  hub        = local.hub

  config_faz = true
  faz_ip     = local.faz_private_ip

  //config_fmg  = true
  //fmg_ip = module.fmg.ni_ips["private"]

  vpc-spoke_cidr = [local.nodes_cidr["azure"]]
}
// Create data templates extra-config fgt
data "template_file" "azure_fgt_1_extra_config" {
  for_each = local.azure_fgt_vips
  template = file("./templates/fgt_extra-config.tpl")
  vars = {
    external_ip   = module.azure_fgt_vnet.fgt-active-ni_ips["public"]
    mapped_ip     = each.value["mapped_ip"]
    external_port = each.value["external_port"]
    mapped_port   = each.value["mapped_port"]
    public_port   = "port1"
    private_port  = "port2"
    suffix        = each.value["external_port"]
  }
}
data "template_file" "azure_fgt_2_extra_config" {
  for_each = local.azure_fgt_vips
  template = file("./templates/fgt_extra-config.tpl")
  vars = {
    external_ip   = module.azure_fgt_vnet.fgt-passive-ni_ips["public"]
    mapped_ip     = each.value["mapped_ip"]
    external_port = each.value["external_port"]
    mapped_port   = each.value["mapped_port"]
    public_port   = "port1"
    private_port  = "port2"
    suffix        = each.value["external_port"]
  }
}
// Create FGT cluster spoke
module "azure_fgt" {
  source = "git::github.com/jmvigueras/modules//azure/fgt-ha"

  prefix                   = local.prefix
  location                 = local.azure_location
  resource_group_name      = local.azure_resource_group_name == null ? azurerm_resource_group.rg[0].name : local.azure_resource_group_name
  tags                     = local.tags
  storage-account_endpoint = local.azure_storage-account_endpoint == null ? azurerm_storage_account.storageaccount[0].primary_blob_endpoint : local.azure_storage-account_endpoint

  admin_username = local.fgt_admin["azure"]
  admin_password = local.fgt_password["azure"]

  fgt-active-ni_ids  = module.azure_fgt_vnet.fgt-active-ni_ids
  fgt-passive-ni_ids = module.azure_fgt_vnet.fgt-passive-ni_ids
  fgt_config_1       = module.azure_fgt_config.fgt_config_1
  fgt_config_2       = module.azure_fgt_config.fgt_config_2

  //license_type = local.fgt_license_type
  //fgt_version = "7.2.5"
  fgt_version = local.fgt_version
  size        = local.fgt_instance_type["azure"]

  fgt_passive = false
}
// Create load balancers
module "azure_xlb" {
  source = "git::github.com/jmvigueras/modules//azure/xlb"

  prefix              = local.prefix
  location            = local.azure_location
  resource_group_name = local.azure_resource_group_name == null ? azurerm_resource_group.rg[0].name : local.azure_resource_group_name

  vnet-fgt           = module.azure_fgt_vnet.vnet
  subnet_ids         = module.azure_fgt_vnet.subnet_ids
  subnet_cidrs       = module.azure_fgt_vnet.subnet_cidrs
  fgt-active-ni_ips  = module.azure_fgt_vnet.fgt-active-ni_ips
  fgt-passive-ni_ips = module.azure_fgt_vnet.fgt-passive-ni_ips

  elb_listeners = local.elb_listeners
}
#--------------------------------------------------------------------------------
# Create route table default
#--------------------------------------------------------------------------------
// Route-table definition
resource "azurerm_route_table" "rt_rfc1918" {
  name                = "${local.prefix}-rt-rfc1918"
  location            = local.azure_location
  resource_group_name = local.azure_resource_group_name == null ? azurerm_resource_group.rg[0].name : local.azure_resource_group_name

  disable_bgp_route_propagation = false

  route {
    name                   = "rfc1918-1"
    address_prefix         = "192.168.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = module.azure_xlb.ilb_private-ip
  }
  route {
    name                   = "rfc1918-2"
    address_prefix         = "172.16.0.0/12"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = module.azure_xlb.ilb_private-ip
  }
  route {
    name                   = "rfc1918-3"
    address_prefix         = "10.0.0.0/8"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = module.azure_xlb.ilb_private-ip
  }
  route {
    name                   = "default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = module.azure_xlb.ilb_private-ip
  }
}
#------------------------------------------------------------------------------
# Create FAZ
#------------------------------------------------------------------------------
// Create FAZ instances
module "faz" {
  source  = "jmvigueras/ftnt-azure-modules/azure//modules/faz"
  version = "0.0.1"

  #source = "./modules/azure_faz"

  prefix                   = local.prefix
  location                 = local.azure_location
  resource_group_name      = local.azure_resource_group_name == null ? azurerm_resource_group.rg[0].name : local.azure_resource_group_name
  tags                     = local.tags
  storage-account_endpoint = local.azure_storage-account_endpoint == null ? azurerm_storage_account.storageaccount[0].primary_blob_endpoint : local.azure_storage-account_endpoint

  size           = local.faz_size
  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  api_key        = trimspace(random_string.api_key.result)
  license_type   = local.faz_license_type
  license_file   = local.faz_license_file

  admin_username = local.fgt_admin["azure"]
  admin_password = local.fgt_password["azure"]

  subnet_ids = {
    public  = module.azure_fgt_vnet.subnet_ids["public"]
    private = module.azure_fgt_vnet.subnet_ids["bastion"]
  }
  subnet_cidrs = {
    public  = module.azure_fgt_vnet.subnet_cidrs["public"]
    private = module.azure_fgt_vnet.subnet_cidrs["bastion"]
  }
}