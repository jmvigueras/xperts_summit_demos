locals {
  #-----------------------------------------------------------------------------------------------------
  # General variables
  #-----------------------------------------------------------------------------------------------------
  prefix = "demo-cnf"
  region = {
    id  = "eu-west-1"
    az1 = "eu-west-1a"
    az2 = "eu-west-1c"
  }

  #-----------------------------------------------------------------------------------------------------
  # VPC spokes
  #-----------------------------------------------------------------------------------------------------
  vpc_central_inspection_cdirs = ["172.20.100.0/24", "172.20.150.0/24"]
  vpc_n-s_inspection_cidr      = "172.20.200.0/24"

  spoke_sdwan_cidrs = ["192.168.0.0/16"]
  
  // Update with FortigateCNF GWLBe deployed from FortigateCNF console
  vpc_n-s_gwlbe_az1_id = "vpce-0d9fe65c1c719761f"
  vpc_n-s_gwlbe_az2_id = "vpce-0d3d7897135664144"
  vpc_tgw_gwlbe_az1_id = "vpce-0a167bceca3b6e350"
  vpc_tgw_gwlbe_az2_id = "vpce-083f0c7a9bb55fa4a"

  /*
  vpc_n-s_gwlbe_az1_id = null
  vpc_n-s_gwlbe_az2_id = null
  vpc_tgw_gwlbe_az1_id = null
  vpc_tgw_gwlbe_az2_id = null
  */

  #-----------------------------------------------------------------------------------------------------
  # FGT SDWAN N-S
  #-----------------------------------------------------------------------------------------------------
  admin_port = "8443"
  admin_cidr = "${chomp(data.http.my-public-ip.response_body)}/32"

  fgt_instance_type = "c6i.large"
  fgt_build         = "build1517"
  fgt_license_type  = "payg"
  sdwan_fgt_passive = false

  fgt_vpc_cidr = "172.20.0.0/24"

  onramp = {
    id      = "onramp"
    cidr    = local.fgt_vpc_cidr
    bgp-asn = local.hub[0]["bgp_asn_spoke"]
  }

  hubs = [for hub in local.hub :
    {
      id                = hub["id"]
      bgp_asn           = hub["bgp_asn_hub"]
      external_ip       = module.fgt_hub.fgt_active_eip_public
      hub_ip            = cidrhost(hub["vpn_cidr"], 1)
      site_ip           = ""
      hck_ip            = cidrhost(hub["vpn_cidr"], 1)
      vpn_psk           = module.fgt_hub_config.vpn_psk
      cidr              = hub["cidr"]
      ike_version       = hub["ike_version"]
      network_id        = hub["network_id"]
      dpd_retryinterval = hub["dpd_retryinterval"]
      sdwan_port        = hub["vpn_port"]
    }
  ]

  #-----------------------------------------------------------------------------------------------------
  # FGT CNF E-W
  #-----------------------------------------------------------------------------------------------------
  fgt_cnf_vpc_cidr = "172.20.10.0/24"

  #-----------------------------------------------------------------------------------------------------
  # FGT HUB
  #-----------------------------------------------------------------------------------------------------
  hub_vpc_cidr    = "192.168.0.0/24"
  hub_fgt_passive = false

  hub = [
    {
      id                = "HUB"
      bgp_asn_hub       = "65000"
      bgp_asn_spoke     = "65000"
      vpn_cidr          = "10.10.10.0/24"
      vpn_psk           = "secret-key-123"
      cidr              = local.hub_vpc_cidr
      ike_version       = "2"
      network_id        = "1"
      dpd_retryinterval = "5"
      mode_cfg          = true
      vpn_port          = "public"
    }
  ]

  #-----------------------------------------------------------------------------------------------------
  # TGW
  #-----------------------------------------------------------------------------------------------------
  tgw_bgp-asn     = "65515"
  tgw_cidr        = ["172.20.50.0/24"]
  tgw_inside_cidr = ["169.254.100.0/29", "169.254.101.0/29"]
}