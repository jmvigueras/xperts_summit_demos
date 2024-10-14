locals {
  #--------------------------------------------------------------------------------------------------
  # General variables
  #--------------------------------------------------------------------------------------------------
  prefix = "votingapp"

  # Clouds to deploy new APP
  csps = ["aws", "azure", "gcp", "oci"]

  #--------------------------------------------------------------------------------------------------
  # Github repo variables
  #--------------------------------------------------------------------------------------------------
  github_site      = "your-github-site"
  github_repo_name = "${local.prefix}-app"

  git_author_email = "your-github-author@local.local"
  git_author_name  = "your-github-author"

  #--------------------------------------------------------------------------------------------------
  # K8S voting app details
  #--------------------------------------------------------------------------------------------------
  # variables used in deployment manifest
  votes_nodeport   = "31000"
  results_nodeport = "31001"

  #-----------------------------------------------------------------------------------------------------
  # AWS Route53
  #-----------------------------------------------------------------------------------------------------
  # AWS Route53 zone
  route53_zone_name = "your-domain.com"
  # AWS region to configure provider
  aws_region = {
    id  = "eu-west-1" //Ireland
    az1 = "eu-west-1a"
    az2 = "eu-west-1c"
  }
  #-----------------------------------------------------------------------------------------------------
  # FortiWEB Cloud
  #-----------------------------------------------------------------------------------------------------
  # Fortiweb Cloud template ID
  fwb_cloud_template = "fwb-cloud-template-id"
  # FortiWEB Cloud regions where deploy
  fortiweb_region = {
    aws   = "eu-west-1"      // Ireland
    azure = "westeurope"     // Netherlands
    gcp   = "europe-west3"   // Frankfurt
    oci   = "eu-frankfurt-1" // Frankfurt
  }
  # FortiWEB Cloud platform names
  fortiweb_platform = {
    aws   = "AWS"
    azure = "Azure"
    gcp   = "GCP"
    oci   = "OCI"
  }

  #--------------------------------------------------------------------------------------------------
  # FGT and K8S secrets
  #--------------------------------------------------------------------------------------------------
  # Import data from day0 
  fgt_values = {
    aws   = data.terraform_remote_state.day0_aws_gcp.outputs.fgt_values["aws"]
    azure = data.terraform_remote_state.day0_oci_az.outputs.fgt_values["azure"]
    gcp   = data.terraform_remote_state.day0_aws_gcp.outputs.fgt_values["gcp"]
    oci   = data.terraform_remote_state.day0_oci_az.outputs.fgt_values["oci"]
  }
  k8s_values_cli = {
    aws   = data.terraform_remote_state.day0_aws_gcp.outputs.k8s_values_cli["aws"]
    azure = data.terraform_remote_state.day0_oci_az.outputs.k8s_values_cli["azure"]
    gcp   = data.terraform_remote_state.day0_aws_gcp.outputs.k8s_values_cli["gcp"]
    oci   = data.terraform_remote_state.day0_oci_az.outputs.k8s_values_cli["oci"]
  }
  k8s_values = {
    aws   = module.get_k8s_values["aws"].results
    azure = module.get_k8s_values["azure"].results
    gcp   = module.get_k8s_values["gcp"].results
    oci   = module.get_k8s_values["oci"].results
  }
}

#--------------------------------------------------------------------------------------------------
# Get data from day0 deployment and execute command to read K8S values
#--------------------------------------------------------------------------------------------------
# Get state file from day0 deployment
data "terraform_remote_state" "day0_oci_az" {
  backend = "local"
  config = {
    path = "../0_day0_IaC_ftnt_az_oci_gcp_k8s/terraform.tfstate"
  }
}
data "terraform_remote_state" "day0_aws_gcp" {
  backend = "local"
  config = {
    path = "../1_day0_IaC_ftnt_aws_gcp_k8s/terraform.tfstate"
  }
}
# Execute commmads to get K8S cluster data
module "get_k8s_values" {
  for_each = toset(local.csps)
  source   = "./modules/exec-command"

  commands = local.k8s_values_cli[each.value]
}