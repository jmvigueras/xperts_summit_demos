#------------------------------------------------------------------------------
# Create HUB AWS
# - VPC FGT hub
# - config FGT hub (FGCP)
# - FGT hub
# - Create test instances in bastion subnet
#------------------------------------------------------------------------------
// Create VPC for hub
module "aws_fgt_vpc" {
  source = "./modules/aws_fgt_vpc_tgw"

  prefix     = "${local.prefix}-fgt"
  admin_cidr = local.fgt_admin_cidr
  admin_port = local.fgt_admin_port
  region     = local.aws_region

  vpc-sec_cidr = local.fgt_cidrs["aws"]

  tgw_id                = module.tgw.tgw_id
  tgw_rt-association_id = module.tgw.rt-vpc-sec-N-S_id
  tgw_rt-propagation_id = module.tgw.rt_vpc-spoke_id
}
// Create config for FGT hub (FGCP)
module "aws_fgt_config" {
  source = "./modules/fgt_config"

  admin_cidr     = local.fgt_admin_cidr
  admin_port     = local.fgt_admin_port
  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  api_key        = trimspace(random_string.api_key.result)

  subnet_cidrs = module.aws_fgt_vpc.subnet_az1_cidrs
  fgt_ni_ips   = module.aws_fgt_vpc.fgt_ni_ips

  license_type    = local.fgt_license_type
  fortiflex_token = local.fortiflex_token["aws"]

  fgt_extra-config = join("\n", [data.template_file.aws_fgt_1_extra_config_api.rendered], [data.template_file.aws_fgt_1_extra_config_redis.rendered])

  config_spoke = true
  hubs         = local.hubs
  spoke        = local.aws_spoke

  config_faz = local.config_faz
  faz_ip     = local.faz_ip
  faz_sn     = local.faz_sn

  vpc-spoke_cidr = [local.nodes_cidr["aws"]]
}
# Create data template extra-config fgt
data "template_file" "aws_fgt_1_extra_config_api" {
  template = file("./templates/fgt_extra-config.tpl")
  vars = {
    external_ip   = module.aws_fgt_vpc.fgt_ni_ips["public"]
    mapped_ip     = local.master_ip["aws"]
    external_port = local.api_port
    mapped_port   = local.api_port
    public_port   = "port1"
    private_port  = "port2"
    suffix        = local.api_port
  }
}
data "template_file" "aws_fgt_1_extra_config_redis" {
  template = file("./templates/fgt_extra-config.tpl")
  vars = {
    external_ip   = module.aws_fgt_vpc.fgt_ni_ips["public"]
    mapped_ip     = local.master_ip["aws"]
    external_port = local.db_port
    mapped_port   = local.db_port
    public_port   = "port1"
    private_port  = "port2"
    suffix        = local.db_port
  }
}
// Create FGT instances
module "aws_fgt" {
  source = "./modules/aws_fgt"

  prefix        = "${local.prefix}-hub"
  region        = local.aws_region
  instance_type = local.fgt_instance_type["aws"]
  keypair       = aws_key_pair.keypair.key_name

  license_type = local.fgt_license_type
  fgt_build    = local.fgt_build


  fgt_ni_ids = module.aws_fgt_vpc.fgt_ni_ids
  fgt_config = module.aws_fgt_config.fgt_config
}

#------------------------------------------------------------------------------
# Create TGW and VPC k8s nodes
#------------------------------------------------------------------------------
// Create TGW
module "tgw" {
  source = "./modules/aws_tgw"

  prefix = local.prefix

  tgw_cidr    = local.tgw_cidr
  tgw_bgp-asn = local.tgw_bgp-asn
}