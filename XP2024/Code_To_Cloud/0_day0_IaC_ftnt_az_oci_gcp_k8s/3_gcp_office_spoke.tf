#------------------------------------------------------------------------------------------------------------
# Create VPCs and subnets Fortigate
# - VPC for MGMT and HA interface
# - VPC for Public interface
# - VPC for Private interface  
#------------------------------------------------------------------------------------------------------------
module "gcp_fgt_office_vpc" {
  source = "./modules/gcp_fgt_vpc"

  region = local.gcp_region["id"]
  prefix = "${local.prefix}-office"

  vpc-sec_cidr = local.gcp_spoke_office_cidr
}
#------------------------------------------------------------------------------------------------------------
# Create RFC1918 routes in VPC private route to FGT active
#------------------------------------------------------------------------------------------------------------
resource "google_compute_route" "route_to-fgt_1" {
  name        = "${local.prefix}-office-route-to-fgt-1"
  dest_range  = "192.168.0.0/16"
  network     = module.gcp_fgt_office_vpc.vpc_names["private"]
  next_hop_ip = module.gcp_fgt_office_vpc.fgt_ni_ips["private"]
  priority    = 100
}
resource "google_compute_route" "route_to-fgt_2" {
  name        = "${local.prefix}-office-route-to-fgt-2"
  dest_range  = "10.0.0.0/8"
  network     = module.gcp_fgt_office_vpc.vpc_names["private"]
  next_hop_ip = module.gcp_fgt_office_vpc.fgt_ni_ips["private"]
  priority    = 100
}
resource "google_compute_route" "route_to-fgt_3" {
  name        = "${local.prefix}-office-route-to-fgt-3"
  dest_range  = "172.16.0.0/12"
  network     = module.gcp_fgt_office_vpc.vpc_names["private"]
  next_hop_ip = module.gcp_fgt_office_vpc.fgt_ni_ips["private"]
  priority    = 100
}
#------------------------------------------------------------------------------------------------------------
# Create FGT cluster config
#------------------------------------------------------------------------------------------------------------
module "gcp_fgt_office_config" {
  source = "./modules/gcp_fgt_config"

  admin_cidr     = local.fgt_admin_cidr
  admin_port     = local.fgt_admin_port
  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  api_key        = trimspace(random_string.api_key.result)

  subnet_cidrs = module.gcp_fgt_office_vpc.subnet_cidrs
  fgt_ni_ips   = module.gcp_fgt_office_vpc.fgt_ni_ips

  license_type    = local.fgt_license_type
  fortiflex_token = local.fortiflex_token["gcp"]

  config_spoke = true
  hubs         = local.hubs
  spoke        = local.gcp_spoke_office

  vpc-spoke_cidr = [local.gcp_spoke_office_cidr]
}
#------------------------------------------------------------------------------------------------------------
# Create FGT cluster instances
#------------------------------------------------------------------------------------------------------------
module "gcp_fgt_office" {
  source = "./modules/gcp_fgt"

  region = local.gcp_region["id"]
  prefix = "${local.prefix}-office"
  zone1  = local.gcp_region["zone1"]

  machine        = local.fgt_instance_type["gcp"]
  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  gcp-user_name  = split("@", data.google_client_openid_userinfo.me.email)[0]
  license_type   = local.fgt_license_type
  fgt_version    = replace(local.fgt_version, ".", "")

  subnet_names = module.gcp_fgt_office_vpc.subnet_names
  fgt_ni_ips   = module.gcp_fgt_office_vpc.fgt_ni_ips

  fgt_config = module.gcp_fgt_office_config.fgt_config
}
# Create office bastion VM
module "gcp_office_vm" {
  source = "./modules/gcp_new_vm"
  prefix = "${local.prefix}-office"
  region = local.gcp_region["id"]
  zone   = local.gcp_region["zone1"]

  machine_type   = local.node_instance_type["gcp"]
  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  gcp-user_name  = local.linux_user["gcp"]
  disk_size      = local.disk_size

  private_ip  = cidrhost(module.gcp_fgt_office_vpc.subnet_cidrs["bastion"], 10)
  subnet_name = module.gcp_fgt_office_vpc.subnet_names["bastion"]
}