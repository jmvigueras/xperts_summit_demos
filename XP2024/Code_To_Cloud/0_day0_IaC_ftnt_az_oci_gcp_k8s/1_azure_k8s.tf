#--------------------------------------------------------------------------
# Create cluster nodes VNET
#--------------------------------------------------------------------------
// Create VPC Nodes K8S cluster
module "azure_nodes_vnet" {
  source = "git::github.com/jmvigueras/modules//azure/vnet-spoke_v2"

  prefix              = local.prefix
  location            = local.azure_location
  resource_group_name = local.azure_resource_group_name == null ? azurerm_resource_group.rg[0].name : local.azure_resource_group_name
  tags                = local.tags

  vnet_spoke_cidr = local.nodes_cidr["azure"]
  # Peer with VNET vnet-fgt
  vnet_fgt = {
    id   = module.azure_fgt_vnet.vnet["id"]
    name = module.azure_fgt_vnet.vnet["name"]
  }
}
/*
// Associate RouteTable to Fortigate
resource "azurerm_subnet_route_table_association" "rta_nodes_subnet_1" {
  subnet_id      = module.azure_nodes_vnet.subnet_ids["subnet_1"]
  route_table_id = azurerm_route_table.rt_rfc1918.id
}
// Associate RouteTable to Fortigate
resource "azurerm_subnet_route_table_association" "rta_nodes_subnet_2" {
  subnet_id      = module.azure_nodes_vnet.subnet_ids["subnet_2"]
  route_table_id = azurerm_route_table.rt_rfc1918.id
}
*/
#--------------------------------------------------------------------------
# Create cluster nodes: master and workers
#--------------------------------------------------------------------------
// Create public IP address for node master
resource "azurerm_public_ip" "master_public_ip" {
  name                = "${local.prefix}-master-pip"
  location            = local.azure_location
  resource_group_name = local.azure_resource_group_name == null ? azurerm_resource_group.rg[0].name : local.azure_resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"

  tags = local.tags
}
// Deploy cluster master node
module "azure_node_master" {
  source = "./modules/azure_new_vm"

  prefix = "${local.prefix}-master"

  location                 = local.azure_location
  resource_group_name      = local.azure_resource_group_name == null ? azurerm_resource_group.rg[0].name : local.azure_resource_group_name
  storage-account_endpoint = local.azure_storage-account_endpoint == null ? azurerm_storage_account.storageaccount[0].primary_blob_endpoint : local.azure_storage-account_endpoint
  vm_size                  = local.node_instance_type["azure"]
  admin_username           = local.linux_user["azure"]
  rsa-public-key           = tls_private_key.ssh.public_key_openssh

  user_data    = data.template_file.azure_node_master.rendered
  public_ip_id = azurerm_public_ip.master_public_ip.id
  public_ip    = azurerm_public_ip.master_public_ip.ip_address
  private_ip   = local.master_ip["azure"]
  subnet_id    = module.azure_nodes_vnet.subnet_ids["subnet_1"]
  subnet_cidr  = module.azure_nodes_vnet.subnet_cidrs["subnet_1"]

  tags = merge(
    local.tags,
    { "quarantine" = "false" }
  )
}
// Create data template for master node
data "template_file" "azure_node_master" {
  template = file("./templates/k8s-master.sh")
  vars = {
    cert_extra_sans = local.master_public_ip["azure"]
    script          = data.template_file.azure_node_master_script.rendered
    k8s_version     = local.k8s_version
    lacework_k8s    = data.template_file.lacework_k8s_yaml.rendered
    db_pass         = local.db_pass
    linux_user      = local.linux_user["azure"]
  }
}
data "template_file" "azure_node_master_script" {
  template = file("./templates/export-k8s-cluster-info.py")
  vars = {
    db_host         = local.db_host["azure"]
    db_port         = local.db_port
    db_pass         = local.db_pass
    db_prefix       = local.db_prefix["azure"]
    master_ip       = local.master_ip["azure"]
    master_api_port = local.api_port
  }
}
data "template_file" "lacework_k8s_yaml" {
  template = file("./templates/lacework-k8s.yaml")
  vars = {
    token      = var.lacework_agent["token"]
    server_url = var.lacework_agent["server_url"]
  }
}

#--------------------------------------------------------------------------
# Create test k8s standalone cluster and NSG to quarantine
#--------------------------------------------------------------------------
// Create NSG Quarantine
resource "azurerm_network_security_group" "nsg-quarantine" {
  name                = "${local.prefix}-nsg-quarantine"
  location            = local.azure_location
  resource_group_name = local.azure_resource_group_name == null ? azurerm_resource_group.rg[0].name : local.azure_resource_group_name

  tags = local.tags
}
resource "azurerm_network_security_rule" "nsg-quarantine-inbound-allow" {
  name                        = "${local.prefix}-nsr-ingress-quarantine-allow"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = module.azure_fgt_vnet.fgt-active-ni_ips["private"]
  destination_address_prefix  = "*"
  resource_group_name         = local.azure_resource_group_name == null ? azurerm_resource_group.rg[0].name : local.azure_resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg-quarantine.name
}
resource "azurerm_network_security_rule" "nsg-quarantine-inbound-deny" {
  name                        = "${local.prefix}-nsr-ingress-quarantine-deny"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = local.azure_resource_group_name == null ? azurerm_resource_group.rg[0].name : local.azure_resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg-quarantine.name
}
resource "azurerm_network_security_rule" "nsg-quarantine-outbound-allow" {
  name                        = "${local.prefix}-nsr-egress-quarantine-allow"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = module.azure_fgt_vnet.fgt-active-ni_ips["private"]
  resource_group_name         = local.azure_resource_group_name == null ? azurerm_resource_group.rg[0].name : local.azure_resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg-quarantine.name
}
resource "azurerm_network_security_rule" "nsg-quarantine-outbound-deny" {
  name                        = "${local.prefix}-nsr-egress-quarantine-deny"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = local.azure_resource_group_name == null ? azurerm_resource_group.rg[0].name : local.azure_resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg-quarantine.name
}
#--------------------------------------------------------------------------
# K8s Deploy Risky node
#
module "azure_k8s_risky" {
  source = "./modules/azure_new_vm"

  prefix                   = "${local.prefix}-k8s-risky"
  location                 = local.azure_location
  resource_group_name      = local.azure_resource_group_name == null ? azurerm_resource_group.rg[0].name : local.azure_resource_group_name
  tags                     = local.tags
  storage-account_endpoint = local.azure_storage-account_endpoint == null ? azurerm_storage_account.storageaccount[0].primary_blob_endpoint : local.azure_storage-account_endpoint
  vm_size                  = local.node_instance_type["azure"]
  admin_username           = local.linux_user["azure"]
  rsa-public-key           = tls_private_key.ssh.public_key_openssh

  user_data   = data.template_file.azure_k8s_risky.rendered
  private_ip  = cidrhost(module.azure_nodes_vnet.subnet_cidrs["subnet_1"], local.node_master_cidrhost + 1)
  subnet_id   = module.azure_nodes_vnet.subnet_ids["subnet_1"]
  subnet_cidr = module.azure_nodes_vnet.subnet_cidrs["subnet_1"]
}
// Create data template for worker node
data "template_file" "azure_k8s_risky" {
  template = file("./templates/k8s-standalone.sh")
  vars = {
    cert_extra_sans = local.master_public_ip["azure"]
    k8s_version     = local.k8s_version
    linux_user      = local.linux_user["azure"]
  }
}