#------------------------------------------------------------------------------------------------------------
# Create FGT VCN and subnets
#------------------------------------------------------------------------------------------------------------
module "oci_fgt_vcn" {
  source           = "./modules/oci_vcn_fgt"
  compartment_ocid = var.compartment_ocid

  region     = local.oci_region
  prefix     = local.prefix
  admin_cidr = local.fgt_admin_cidr
  admin_port = local.fgt_admin_port

  vcn_cidr = local.fgt_cidrs["oci"]
}
#------------------------------------------------------------------------------------------------------------
# Create FGT cluster config
#------------------------------------------------------------------------------------------------------------
// Create FGT config
module "oci_fgt_config" {
  source           = "./modules/oci_fgt_config"
  tenancy_ocid     = var.tenancy_ocid
  compartment_ocid = var.compartment_ocid

  admin_cidr     = local.fgt_admin_cidr
  admin_port     = local.fgt_admin_port
  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  api_key        = trimspace(random_string.api_key.result)

  subnet_cidrs = module.oci_fgt_vcn.subnet_cidrs
  fgt_ni_ips   = module.oci_fgt_vcn.fgt_ni_ips

  license_type    = local.fgt_license_type
  fortiflex_token = local.fortiflex_token["oci"]

  fgt_extra-config = join("\n", [data.template_file.oci_fgt_extra_config_api.rendered], [data.template_file.oci_fgt_extra_config_redis.rendered])

  config_spoke = true
  hubs         = local.hubs
  spoke        = local.oci_spoke

  vpc-spoke_cidr = [local.nodes_cidr["oci"]]
}

// Create data template extra-config fgt
data "template_file" "oci_fgt_extra_config_api" {
  template = file("./templates/fgt_extra-config.tpl")
  vars = {
    external_ip   = module.oci_fgt_vcn.fgt_ni_ips["public"]
    mapped_ip     = local.master_ip["oci"]
    external_port = local.api_port
    mapped_port   = local.api_port
    public_port   = "port1"
    private_port  = "port2"
    suffix        = local.api_port
  }
}
data "template_file" "oci_fgt_extra_config_redis" {
  template = file("./templates/fgt_extra-config.tpl")
  vars = {
    external_ip   = module.oci_fgt_vcn.fgt_ni_ips["public"]
    mapped_ip     = local.master_ip["oci"]
    external_port = local.db_port
    mapped_port   = local.db_port
    public_port   = "port1"
    private_port  = "port2"
    suffix        = local.db_port
  }
}
#------------------------------------------------------------------------------------------------------------
# Create FGT cluster instances
#------------------------------------------------------------------------------------------------------------
module "oci_fgt" {
  source           = "./modules/oci_fgt"
  compartment_ocid = var.compartment_ocid

  region = local.oci_region
  prefix = local.prefix

  license_type  = local.fgt_license_type
  ocpus         = 2
  memory_in_gbs = 8

  fgt_config     = module.oci_fgt_config.fgt_config
  fgt_vcn_id     = module.oci_fgt_vcn.vcn_id
  fgt_subnet_ids = module.oci_fgt_vcn.subnet_ids
  fgt_nsg_ids    = module.oci_fgt_vcn.nsg_ids
  fgt_ips        = module.oci_fgt_vcn.fgt_ni_ips
}
#------------------------------------------------------------------------------------------------------------
# Create Local Peering Gateway for VCN 
#------------------------------------------------------------------------------------------------------------
module "oci_fgt_lpg" {
  source           = "./modules/oci_lpg"
  compartment_ocid = var.compartment_ocid

  prefix = local.prefix

  fgt_vcn_id           = module.oci_fgt_vcn.vcn_id
  fgt_subnet_ids       = module.oci_fgt_vcn.subnet_ids
  fgt_vcn_rt_to_fgt_id = module.oci_fgt.fgt_vcn_rt_to_fgt_id
}

#------------------------------------------------------------------------------------------------------------
# Export OCI config
#------------------------------------------------------------------------------------------------------------
resource "local_file" "oci_fgt_config" {
  content         = module.oci_fgt_config.fgt_config
  filename        = "./assets/oci_fgt_config"
  file_permission = "0600"
}






