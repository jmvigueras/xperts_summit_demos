locals {
  #-----------------------------------------------------------------------------------------------------
  # Context locals
  #-----------------------------------------------------------------------------------------------------
  r1_resource_group_name   = null            // it will create a new one if null
  r2_resource_group_name   = null            // it will create a new one if null
  storage-account_endpoint = null            // it will create a new one if null
  region_1                 = "francecentral" // region 1
  prefix                   = "demo-experts"  // prefix added in azure assets

  tags = {
    Deploy  = "Forti demo vwan"
    Project = "Forti SDWAN"
  }

  admin_port     = "8443"
  admin_username = "azureadmin"
  admin_password = "Terraform123#"

  fgt_size         = "Standard_F4s"
  fmg-faz_size     = "Standard_F4s"
  fgt_license_type = "payg"

  faz_license_type = "byol"
  faz_license_file = "./licenses/licenseFAZ.lic"
  fmg_license_type = "byol"
  fmg_license_file = "./licenses/licenseFMG.lic"

  admin_cidr = "${chomp(data.http.my-public-ip.response_body)}/32"

  #-----------------------------------------------------------------------------------------------------
  # vWAN
  #-----------------------------------------------------------------------------------------------------
  r1_vhub_cidr       = "172.30.10.0/23"
  r1_vhub_vnet_cidrs = ["172.30.200.0/23", "172.30.210.0/23"]

  #-----------------------------------------------------------------------------------------------------
  # FGT HUB locals
  #-----------------------------------------------------------------------------------------------------
  r1_hub_cluster_type = "fgcp"

  r1_hub_vnet_cidr       = "172.30.0.0/24"
  r1_hub_vnet_spoke_cidr = "172.30.100.0/24"

  r1_hub = [
    {
      id                = "HUB"
      bgp_asn_hub       = "65000"
      bgp_asn_spoke     = "65000"
      vpn_cidr          = "10.0.1.0/24"
      vpn_psk           = "secret-key-123"
      cidr              = "172.30.0.0/16"
      ike_version       = "2"
      network_id        = "1"
      dpd_retryinterval = "5"
      mode_cfg          = true
      vpn_port          = "public"
      local_gw          = ""
    }
  ]
  #-----------------------------------------------------------------------------------------------------
  # LB locals
  #-----------------------------------------------------------------------------------------------------
  config_gwlb        = false
  r1_ilb_ip          = cidrhost(module.r1_hub_vnet.subnet_cidrs["private"], 9)
  backend-probe_port = "8008"
  #-----------------------------------------------------------------------------------------------------
  # FGT Spoke to HUB (region 1)
  #-----------------------------------------------------------------------------------------------------
  spoke_number       = 1
  spoke_cluster_type = "fgcp"

  spoke_hub = {
    id      = "spoke-hub"
    cidr    = "192.168.0.0/23"
    bgp_asn = local.r1_hub[0]["bgp_asn_spoke"]
  }

  sdwan_hubs = concat(local.sdwan_hub, local.r1_hub_cluster_type == "fgsp" ? local.sdwan_hub_fgsp : [])

  sdwan_hub = [for hub in local.r1_hub :
    {
      id                = hub["id"]
      bgp_asn           = hub["bgp_asn_hub"]
      external_ip       = hub["vpn_port"] == "public" ? module.r1_xlb.elb_public-ip : local.r1_ilb_ip
      hub_ip            = cidrhost(cidrsubnet(hub["vpn_cidr"], local.r1_hub_cluster_type == "fgsp" ? 1 : 0, 0), 1)
      site_ip           = hub["mode_cfg"] ? "" : cidrhost(cidrsubnet(hub["vpn_cidr"], local.r1_hub_cluster_type == "fgsp" ? 1 : 0, 0), 2)
      hck_ip            = cidrhost(cidrsubnet(hub["vpn_cidr"], local.r1_hub_cluster_type == "fgsp" ? 1 : 0, 0), 1)
      vpn_psk           = hub["vpn_psk"]
      cidr              = hub["cidr"]
      ike_version       = hub["ike_version"]
      network_id        = hub["network_id"]
      dpd_retryinterval = hub["dpd_retryinterval"]
      sdwan_port        = hub["vpn_port"]
    }
  ]
  sdwan_hub_fgsp = [for hub in local.r1_hub :
    {
      id                = hub["id"]
      bgp_asn           = hub["bgp_asn_hub"]
      external_ip       = hub["vpn_port"] == "public" ? module.r1_xlb.elb_public-ip : local.r1_ilb_ip
      hub_ip            = cidrhost(cidrsubnet(hub["vpn_cidr"], 1, 1), 1)
      site_ip           = hub["mode_cfg"] ? "" : cidrhost(cidrsubnet(hub["vpn_cidr"], 1, 1), 2)
      hck_ip            = cidrhost(cidrsubnet(hub["vpn_cidr"], 1, 1), 1)
      vpn_psk           = hub["vpn_psk"]
      cidr              = hub["cidr"]
      ike_version       = hub["ike_version"]
      network_id        = hub["network_id"]
      dpd_retryinterval = hub["dpd_retryinterval"]
      sdwan_port        = hub["vpn_port"]
    }
  ]
  #-----------------------------------------------------------------------------------------------------
  # FGT Spoke to vHUB (region 1)
  #-----------------------------------------------------------------------------------------------------
  spoke_vhub = {
    id      = "spoke-vhub"
    cidr    = "192.168.10.0/23"
    bgp_asn = local.r1_hub[0]["bgp_asn_spoke"]
  }

  vhub_hub = [
    {
      id                = "vHUB"
      bgp_asn           = "65001"
      external_ip       = "1.1.1.1"
      hub_ip            = "10.0.2.1"
      site_ip           = ""
      hck_ip            = "10.0.2.1"
      vpn_psk           = local.r1_hub[0]["vpn_psk"]
      cidr              = local.r1_hub[0]["cidr"]
      ike_version       = local.r1_hub[0]["ike_version"]
      network_id        = local.r1_hub[0]["network_id"]
      dpd_retryinterval = local.r1_hub[0]["dpd_retryinterval"]
      sdwan_port        = "public"
    },
    {
      id                = "vHUB"
      bgp_asn           = "65001"
      external_ip       = "1.1.1.2"
      hub_ip            = "10.0.2.2"
      site_ip           = ""
      hck_ip            = "10.0.2.1"
      vpn_psk           = local.r1_hub[0]["vpn_psk"]
      cidr              = local.r1_hub[0]["cidr"]
      ike_version       = local.r1_hub[0]["ike_version"]
      network_id        = local.r1_hub[0]["network_id"]
      dpd_retryinterval = local.r1_hub[0]["dpd_retryinterval"]
      sdwan_port        = "public"
    }
  ]
}