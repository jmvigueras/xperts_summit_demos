locals {
  #-----------------------------------------------------------------------------------------------------
  # General variables
  #-----------------------------------------------------------------------------------------------------
  prefix = "multicloud"

  # Clouds to deploy
  csps = ["oci", "azure"]

  tags = {
    Deploy   = "demo multi-cloud"
    Project  = "platform-engineering"
    Username = "jvigueras"
  }
  gcp_region = {
    id    = "europe-west4" // Netherlands
    zone1 = "europe-west4-a"
    zone2 = "europe-west4-c"
  }
  azure_location                 = "francecentral" // Amsterdam
  azure_resource_group_name      = null            // a new resource group will be created if null
  azure_storage-account_endpoint = null            // a new resource group will be created if null

  oci_region = "eu-frankfurt-1"
  #-----------------------------------------------------------------------------------------------------
  # FGT Clusters
  #-----------------------------------------------------------------------------------------------------
  fgt_admin_port = "8443"
  //fgt_admin_cidr = "0.0.0.0/0"
  fgt_admin_cidr = "${chomp(data.http.my-public-ip.response_body)}/32"

  fgt_license_type = "byol"
  fortiflex_token = {
    oci = "XXXXXXXXXX" //FGVMMLTMxxxxxxxx
    gcp = "XXXXXXXXXX"  //FGVMMLTMxxxxxxxx
  }

  fgt_version = "7.2.9"
  fgt_instance_type = {
    aws   = "c6i.large"
    azure = "Standard_F4s"
    gcp   = "n1-standard-4"
    oci   = "VM.Standard2.4"
  }
  fgt_cidrs = {
    azure = "172.16.0.0/23"
    oci   = "172.20.0.0/23"
    aws   = "172.24.0.0/23"
    gcp   = "172.28.0.0/23"
  }
  fgt_admin = {
    azure = "azureadmin"
  }
  fgt_password = {
    azure = "Terraform123#"
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
    azure = module.azure_xlb.elb_public-ip
    oci   = module.oci_fgt.fgt_public_ip_public
  }
  db_host_public_ip = {
    azure = module.azure_xlb.elb_public-ip
    oci   = module.oci_fgt.fgt_public_ip_public
  }
  master_ip = {
    azure = cidrhost(module.azure_nodes_vnet.subnet_cidrs["subnet_1"], local.node_master_cidrhost)
    oci   = cidrhost(local.nodes_cidr["oci"], local.node_master_cidrhost)
  }
  db_host = {
    azure = cidrhost(module.azure_nodes_vnet.subnet_cidrs["subnet_1"], local.node_master_cidrhost)
    oci   = cidrhost(local.nodes_cidr["oci"], local.node_master_cidrhost)
  }
  db_port = "6379"
  db_pass = random_string.db_pass.result
  db_prefix = {
    aws   = "aws"
    azure = "azure"
    gcp   = "gcp"
    oci   = "oci"
  }

  api_port = "6443"

  #-----------------------------------------------------------------------------------------------------
  # Azure FGT HUB
  #-----------------------------------------------------------------------------------------------------
  // VPN DialUp variables
  hub = [{
    id                = "hub"
    bgp_asn_hub       = "65000"
    bgp_asn_spoke     = "65000"
    vpn_cidr          = "10.10.10.0/24"
    vpn_psk           = "ysVfxqJRDrWCovRnxRDGwuwMaFuX3M"
    cidr              = local.fgt_cidrs["azure"]
    ike_version       = "2"
    network_id        = "1"
    dpd_retryinterval = "5"
    mode_cfg          = true
    vpn_port          = "public"
    local_gw          = ""
  }]
  // Variable for spoke to connect to HUB
  hubs = [{
    id                = local.hub[0]["id"]
    bgp_asn           = local.hub[0]["bgp_asn_hub"]
    external_ip       = module.azure_xlb.elb_public-ip
    hub_ip            = cidrhost(local.hub[0]["vpn_cidr"], 1)
    site_ip           = "" // set to "" if VPN mode-cfg is enable
    hck_ip            = cidrhost(local.hub[0]["vpn_cidr"], 1)
    vpn_psk           = local.hub[0]["vpn_psk"]
    cidr              = local.hub[0]["cidr"]
    ike_version       = local.hub[0]["ike_version"]
    network_id        = local.hub[0]["network_id"]
    dpd_retryinterval = local.hub[0]["dpd_retryinterval"]
    sdwan_port        = local.hub[0]["vpn_port"]
  }]
  // Azure External LB listernes
  elb_listeners = {
    "80"                     = "Tcp"
    "443"                    = "Tcp"
    "500"                    = "Udp"
    "4500"                   = "Udp"
    "31000"                  = "Tcp"
    "31001"                  = "Tcp"
    "2222"                   = "Tcp"
    "2223"                   = "Tcp"
    "4444"                   = "Tcp"
    tostring(local.db_port)  = "Tcp"
    tostring(local.api_port) = "Tcp"
  }
  // List of ports and mapped IP to create VIPs in Fortigate
  azure_fgt_vips = {
    "vip1" = {
      "external_port" = "${local.api_port}"
      "mapped_port"   = "${local.api_port}"
      "mapped_ip"     = local.master_ip["azure"]
    },
    "vip2" = {
      "external_port" = "${local.db_port}"
      "mapped_port"   = "${local.db_port}"
      "mapped_ip"     = local.master_ip["azure"]
    },
    "vip3" = {
      "external_port" = "2222"
      "mapped_port"   = "22"
      "mapped_ip"     = local.master_ip["azure"]
    },
    "vip4" = {
      "external_port" = "2223"
      "mapped_port"   = "22"
      "mapped_ip"     = cidrhost(module.azure_nodes_vnet.subnet_cidrs["subnet_1"], local.node_master_cidrhost + 1)
    },
    "vip5" = {
      "external_port" = "4444"
      "mapped_port"   = "443"
      "mapped_ip"     = local.faz_private_ip
    }
  }
  #-----------------------------------------------------------------------------------------------------
  # OCI FGT ONRAMP
  #-----------------------------------------------------------------------------------------------------
  // OCI spoke details
  oci_spoke = {
    id      = "oci"
    cidr    = local.fgt_cidrs["oci"]
    bgp_asn = local.hub[0]["bgp_asn_spoke"]
  }

  #-----------------------------------------------------------------------------------------------------
  # GCP FGT OFFICE
  #-----------------------------------------------------------------------------------------------------
  gcp_spoke_office_cidr = "192.168.0.0/23"
  gcp_spoke_office = {
    id      = "on-prem"
    cidr    = local.gcp_spoke_office_cidr
    bgp_asn = local.hub[0]["bgp_asn_spoke"]
  }

  #------------------------------------------------------------------------------
  # Create FAZ
  #------------------------------------------------------------------------------
  faz_size         = "Standard_D4s_v4"
  faz_license_type = "byol"
  faz_license_file = "./licenses/licenseFAZ.lic"

  faz_private_ip = cidrhost(module.azure_fgt_vnet.subnet_cidrs["bastion"], 12)
}
