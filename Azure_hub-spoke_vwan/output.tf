#-----------------------------------------------------------------------------------------------------
# HUB 1
#-----------------------------------------------------------------------------------------------------
output "r1_hub" {
  value = {
    admin        = local.admin_username
    pass         = local.admin_password
    active_mgmt  = "https://${module.r1_hub_vnet.fgt-active-mgmt-ip}:${local.admin_port}"
    passive_mgmt = "https://${module.r1_hub_vnet.fgt-passive-mgmt-ip}:${local.admin_port}"
  }
}
#-----------------------------------------------------------------------------------------------------
# VWAN
#-----------------------------------------------------------------------------------------------------
output "r1_vhub_vnet_vm" {
  value = module.r1_vhub_vnet_vm.*.vm
}
#-----------------------------------------------------------------------------------------------------
# Spokes
#-----------------------------------------------------------------------------------------------------
output "r1_spoke_hub" {
  value = {
    username   = "admin"
    pass       = local.admin_password
    fgt-1_mgmt = module.r1_spoke_hub_vnet.*.fgt-active-mgmt-ip
    admin_cidr = "${chomp(data.http.my-public-ip.response_body)}/32"
  }
}
output "r1_spoke_hub_vm" {
  value = module.r1_spoke_hub_vm.*.vm
}
#-----------------------------------------------------------------------------------------------------
# FAZ and FMG
#-----------------------------------------------------------------------------------------------------
output "faz" {
  value = {
    faz_mgmt = "https://${module.faz.faz_public_ip}"
    faz_pass = local.admin_password
  }
}
output "fmg" {
  value = {
    fmg_mgmt = "https://${module.fmg.fmg_public_ip}"
    fmg_pass = local.admin_password
  }
}