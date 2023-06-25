#------------------------------------------------------------------
# Create vWAN 
# - Create vWAN and vHUB
# - Create vNet spoke associated to vWAN
# - Create VM in vNet spoke
#------------------------------------------------------------------
// Create vWAN and vHUB
module "r1_vwan" {
  depends_on = [module.r1_vhub_vnet, module.r1_hub_vnet]
  source     = "./modules/vwan"

  prefix              = "${local.prefix}-r1"
  location            = local.region_1
  resource_group_name = local.r1_resource_group_name == null ? azurerm_resource_group.r1_rg[0].name : local.r1_resource_group_name
  tags                = local.tags

  vhub_cidr              = local.r1_vhub_cidr
  vnet_connection        = module.r1_vhub_vnet.*.vnet_id
  vnet-fgt_id            = module.r1_hub_vnet.vnet["id"]
  fgt-cluster_active-ip  = module.r1_hub_vnet.fgt-active-ni_ips["private"]
  fgt-cluster_passive-ip = module.r1_hub_vnet.fgt-passive-ni_ips["private"]
  fgt-cluster_bgp-asn    = local.r1_hub[0]["bgp_asn_hub"]
}
// Create vNet spoke
module "r1_vhub_vnet" {
  source = "git::github.com/jmvigueras/modules//azure/vnet-spoke_v2"
  count  = length(local.r1_vhub_vnet_cidrs)

  prefix              = "${local.prefix}-r1-vhub-vnet-${count.index + 1}"
  location            = local.region_1
  resource_group_name = local.r1_resource_group_name == null ? azurerm_resource_group.r1_rg[0].name : local.r1_resource_group_name
  tags                = local.tags

  vnet_spoke_cidr = local.r1_vhub_vnet_cidrs[count.index]
  vnet_fgt        = null
}
// Create VM in vNet spoke
module "r1_vhub_vnet_vm" {
  source = "git::github.com/jmvigueras/modules//azure/new-vm_rsa-ssh_v2"
  count  = length(local.r1_vhub_vnet_cidrs)

  prefix                   = "${local.prefix}-r1-vhub-vnet-${count.index + 1}"
  location                 = local.region_1
  resource_group_name      = local.r1_resource_group_name == null ? azurerm_resource_group.r1_rg[0].name : local.r1_resource_group_name
  tags                     = local.tags
  storage-account_endpoint = local.storage-account_endpoint == null ? azurerm_storage_account.r1_storageaccount[0].primary_blob_endpoint : local.storage-account_endpoint
  admin_username           = local.admin_username
  rsa-public-key           = trimspace(tls_private_key.ssh.public_key_openssh)

  subnet_id   = module.r1_vhub_vnet[count.index].subnet_ids["subnet_1"]
  subnet_cidr = module.r1_vhub_vnet[count.index].subnet_cidrs["subnet_1"]
}
