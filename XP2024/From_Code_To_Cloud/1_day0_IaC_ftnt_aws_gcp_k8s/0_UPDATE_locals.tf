locals {
  #-----------------------------------------------------------------------------------------------------
  # General variables
  #-----------------------------------------------------------------------------------------------------
  prefix = "multicloud"

  # Clouds to deploy
  csps = ["aws", "gcp"]

  tags = {
    Deploy  = "demo multi-cloud"
    Project = "platform-engineering"
  }
  gcp_region = {
    id    = "europe-west4" // Netherlands
    zone1 = "europe-west4-a"
    zone2 = "europe-west4-c"
  }
  aws_region = {
    id  = "eu-west-3" // Paris
    az1 = "eu-west-3a"
    az2 = "eu-west-3c"
  }

  #-----------------------------------------------------------------------------------------------------
  # FGT Clusters
  #-----------------------------------------------------------------------------------------------------
  fgt_admin_port = "8443"
  fgt_admin_cidr = "0.0.0.0/0"

  fgt_license_type = "byol"
  fortiflex_token = {
    aws = "xxxxxx" //FGVMMLTM12345678
    gcp = "xxxxxx" //FGVMMLTM12345679
  }

  fgt_build   = "build2662"
  fgt_version = "745"
  fgt_instance_type = {
    aws   = "c6i.large"
    azure = "Standard_F4s"
    gcp   = "n1-standard-4"
    oci   = "VM.Standard3.Flex"
  }
  fgt_cidrs = {
    azure = "172.16.0.0/23"
    oci   = "172.20.0.0/23"
    aws   = "172.24.0.0/23"
    gcp   = "172.28.0.0/23"
  }

  #-----------------------------------------------------------------------------------------------------
  # K8S Clusters
  #-----------------------------------------------------------------------------------------------------
  worker_number        = 1
  k8s_version          = "1.30"
  node_master_cidrhost = 10 //Network IP address for master node
  disk_size            = 30

  linux_user = {
    aws   = "ubuntu"
    azure = "azureadmin"
    gcp   = split("@", data.google_client_openid_userinfo.me.email)[0]
    oci   = "ubuntu"
  }
  node_instance_type = {
    aws   = "t3.2xlarge"
    azure = "Standard_B2ms"
    gcp   = "e2-standard-4"
    oci   = "VM.Standard3.Flex"
  }
  nodes_cidr = {
    azure = "172.16.20.0/23"
    oci   = "172.20.20.0/23"
    aws   = "172.24.20.0/23"
    gcp   = "172.28.20.0/23"

  }
  master_public_ip = {
    aws = module.aws_fgt.fgt_eip_public
    gcp = module.gcp_fgt.fgt_eip_public
  }
  db_host_public_ip = {
    aws = module.aws_fgt.fgt_eip_public
    gcp = module.gcp_fgt.fgt_eip_public
  }
  master_ip = {
    aws = cidrhost(local.aws_nodes_subnet_cidr, local.node_master_cidrhost)
    gcp = cidrhost(local.nodes_cidr["gcp"], local.node_master_cidrhost)
  }
  db_host = {
    aws = cidrhost(local.aws_nodes_subnet_cidr, local.node_master_cidrhost)
    gcp = cidrhost(local.nodes_cidr["gcp"], local.node_master_cidrhost)
  }
  db_port = 6379
  db_pass = random_string.db_pass.result
  db_prefix = {
    aws   = "aws"
    azure = "azure"
    gcp   = "gcp"
    oci   = "oci"
  }

  api_port = 6443

  #-----------------------------------------------------------------------------------------------------
  # FGT SDWAN HUB to connect
  #-----------------------------------------------------------------------------------------------------
  hubs = data.terraform_remote_state.day0.outputs.hubs_sdwan_details
  hub  = data.terraform_remote_state.day0.outputs.hub_sdwan_details

  config_faz = true
  faz_ip     = "172.16.1.12"
  faz_sn     = "FAZ-VMTM24003529"

  #-----------------------------------------------------------------------------------------------------
  # GCP FGT ONRAMP
  #-----------------------------------------------------------------------------------------------------
  gcp_spoke = {
    id      = "gcp"
    cidr    = local.fgt_cidrs["gcp"]
    bgp_asn = local.hub[0]["bgp_asn_spoke"]
  }

  #-----------------------------------------------------------------------------------------------------
  # AWS FGT ONRAMP
  #-----------------------------------------------------------------------------------------------------
  aws_spoke = {
    id      = "aws"
    cidr    = local.fgt_cidrs["aws"]
    bgp_asn = local.hub[0]["bgp_asn_spoke"]
  }

  tgw_bgp-asn     = "65515"
  tgw_cidr        = ["172.24.10.0/24"]
  tgw_inside_cidr = ["169.254.100.0/29", "169.254.101.0/29"]

  aws_nodes_subnet_id   = module.aws_nodes_vpc.subnet_az1_ids["vm"]
  aws_nodes_subnet_cidr = module.aws_nodes_vpc.subnet_az1_cidrs["vm"]
  aws_nodes_sg_id       = module.aws_nodes_vpc.nsg_ids["vm"]

}

# Get variables definition from day0_IaC_ftnt_aws_az_k8s
data "terraform_remote_state" "day0" {
  backend = "local"
  config = {
    path = "../0_day0_IaC_ftnt_az_oci_gcp_k8s/terraform.tfstate"
  }
}