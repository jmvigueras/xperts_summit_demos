# ------------------------------------------------------------------------------------------
# Azure Define a new VIP resource
# ------------------------------------------------------------------------------------------
# Create VIP address votes APP
resource "fortios_firewall_vip" "azure_app_vip_votes" {
  provider = fortios.azure
  count    = contains(local.csps, "azure") ? 1 : 0

  name = "vip-${local.fgt_values["azure"]["MAPPED_IP"]}-${local.votes_nodeport}"

  type        = "static-nat"
  extintf     = "port1"
  extip       = local.fgt_values["azure"]["EXTERNAL_IP"]
  extport     = local.votes_nodeport
  mappedport  = local.votes_nodeport
  portforward = "enable"

  mappedip {
    range = local.fgt_values["azure"]["MAPPED_IP"]
  }
}
# Create VIP address results APP
resource "fortios_firewall_vip" "azure_app_vip_results" {
  provider = fortios.azure
  count    = contains(local.csps, "azure") ? 1 : 0

  name = "vip-${local.fgt_values["azure"]["MAPPED_IP"]}-${local.results_nodeport}"

  type        = "static-nat"
  extintf     = "port1"
  extip       = local.fgt_values["azure"]["EXTERNAL_IP"]
  extport     = local.results_nodeport
  mappedport  = local.results_nodeport
  portforward = "enable"

  mappedip {
    range = local.fgt_values["azure"]["MAPPED_IP"]
  }
}
# Create group of VIPs
resource "fortios_firewall_vipgrp" "azure_app_vipgrp" {
  provider = fortios.azure
  count    = contains(local.csps, "azure") ? 1 : 0

  interface = "port1"
  name      = "vipgrp-${local.fgt_values["azure"]["MAPPED_IP"]}-app"

  member {
    name = element(fortios_firewall_vip.azure_app_vip_votes, 0).name
  }
  member {
    name = element(fortios_firewall_vip.azure_app_vip_results, 0).name
  }
}
# Define a new firewall policy with default intrusion prevention profile
resource "fortios_firewall_policy" "azure_app_policy" {
  provider   = fortios.azure
  depends_on = [fortios_firewall_vipgrp.azure_app_vipgrp]
  count      = contains(local.csps, "azure") ? 1 : 0

  name = "vip-${local.fgt_values["azure"]["EXTERNAL_IP"]}-vote-app"

  schedule        = "always"
  action          = "accept"
  utm_status      = "enable"
  ips_sensor      = "all_default_pass"
  ssl_ssh_profile = "certificate-inspection"
  nat             = "enable"
  logtraffic      = "all"

  dstintf {
    name = "port2"
  }
  srcintf {
    name = "port1"
  }
  srcaddr {
    name = "all"
  }
  dstaddr {
    name = "vipgrp-${local.fgt_values["azure"]["MAPPED_IP"]}-app"
  }
  service {
    name = "ALL"
  }
}
# ------------------------------------------------------------------------------------------
# OCI Define a new VIP resource
# ------------------------------------------------------------------------------------------
# Create VIP address votes APP
resource "fortios_firewall_vip" "oci_app_vip_votes" {
  provider = fortios.oci
  count    = contains(local.csps, "oci") ? 1 : 0

  name = "vip-${local.fgt_values["oci"]["MAPPED_IP"]}-${local.votes_nodeport}"

  type        = "static-nat"
  extintf     = "port1"
  extip       = local.fgt_values["oci"]["EXTERNAL_IP"]
  extport     = local.votes_nodeport
  mappedport  = local.votes_nodeport
  portforward = "enable"

  mappedip {
    range = local.fgt_values["oci"]["MAPPED_IP"]
  }
}
# Create VIP address results APP
resource "fortios_firewall_vip" "oci_app_vip_results" {
  provider = fortios.oci
  count    = contains(local.csps, "oci") ? 1 : 0

  name = "vip-${local.fgt_values["oci"]["MAPPED_IP"]}-${local.results_nodeport}"

  type        = "static-nat"
  extintf     = "port1"
  extip       = local.fgt_values["oci"]["EXTERNAL_IP"]
  extport     = local.results_nodeport
  mappedport  = local.results_nodeport
  portforward = "enable"

  mappedip {
    range = local.fgt_values["oci"]["MAPPED_IP"]
  }
}
# Create group of VIPs
resource "fortios_firewall_vipgrp" "oci_app_vipgrp" {
  provider = fortios.oci
  count    = contains(local.csps, "oci") ? 1 : 0

  interface = "port1"
  name      = "vipgrp-${local.fgt_values["oci"]["MAPPED_IP"]}-app"

  member {
    name = element(fortios_firewall_vip.oci_app_vip_votes, 0).name
  }
  member {
    name = element(fortios_firewall_vip.oci_app_vip_results, 0).name
  }
}
# Define a new firewall policy with default intrusion prevention profile
resource "fortios_firewall_policy" "oci_app_policy" {
  provider   = fortios.oci
  depends_on = [fortios_firewall_vipgrp.oci_app_vipgrp]
  count      = contains(local.csps, "oci") ? 1 : 0

  name = "vip-${local.fgt_values["oci"]["EXTERNAL_IP"]}-vote-app"

  schedule        = "always"
  action          = "accept"
  utm_status      = "enable"
  ips_sensor      = "all_default_pass"
  ssl_ssh_profile = "certificate-inspection"
  nat             = "enable"
  logtraffic      = "all"

  dstintf {
    name = "port2"
  }
  srcintf {
    name = "port1"
  }
  srcaddr {
    name = "all"
  }
  dstaddr {
    name = "vipgrp-${local.fgt_values["oci"]["MAPPED_IP"]}-app"
  }
  service {
    name = "ALL"
  }
}
/*
# ------------------------------------------------------------------------------------------
# AWS Define a new VIP resource
# ------------------------------------------------------------------------------------------
# Create VIP address votes APP
resource "fortios_firewall_vip" "aws_app_vip_votes" {
  provider = fortios.aws
  count    = contains(local.csps, "aws") ? 1 : 0

  name = "vip-${local.fgt_values["aws"]["MAPPED_IP"]}-${local.votes_nodeport}"

  type        = "static-nat"
  extintf     = "port1"
  extip       = local.fgt_values["aws"]["EXTERNAL_IP"]
  extport     = local.votes_nodeport
  mappedport  = local.votes_nodeport
  portforward = "enable"

  mappedip {
    range = local.fgt_values["aws"]["MAPPED_IP"]
  }
}
# Create VIP address results APP
resource "fortios_firewall_vip" "aws_app_vip_results" {
  provider = fortios.aws
  count    = contains(local.csps, "aws") ? 1 : 0

  name = "vip-${local.fgt_values["aws"]["MAPPED_IP"]}-${local.results_nodeport}"

  type        = "static-nat"
  extintf     = "port1"
  extip       = local.fgt_values["aws"]["EXTERNAL_IP"]
  extport     = local.results_nodeport
  mappedport  = local.results_nodeport
  portforward = "enable"

  mappedip {
    range = local.fgt_values["aws"]["MAPPED_IP"]
  }
}
# Create group of VIPs
resource "fortios_firewall_vipgrp" "aws_app_vipgrp" {
  provider = fortios.aws
  count    = contains(local.csps, "aws") ? 1 : 0

  interface = "port1"
  name      = "vipgrp-${local.fgt_values["aws"]["MAPPED_IP"]}-app"

  member {
    name = element(fortios_firewall_vip.aws_app_vip_votes, 0).name
  }
  member {
    name = element(fortios_firewall_vip.aws_app_vip_results, 0).name
  }
}
# Define a new firewall policy with default intrusion prevention profile
resource "fortios_firewall_policy" "aws_app_policy" {
  provider   = fortios.aws
  depends_on = [fortios_firewall_vipgrp.aws_app_vipgrp]
  count      = contains(local.csps, "aws") ? 1 : 0

  name = "vip-${local.fgt_values["aws"]["EXTERNAL_IP"]}-vote-app"

  schedule        = "always"
  action          = "accept"
  utm_status      = "enable"
  ips_sensor      = "all_default_pass"
  ssl_ssh_profile = "certificate-inspection"
  nat             = "enable"
  logtraffic      = "all"

  dstintf {
    name = "port2"
  }
  srcintf {
    name = "port1"
  }
  srcaddr {
    name = "all"
  }
  dstaddr {
    name = "vipgrp-${local.fgt_values["aws"]["MAPPED_IP"]}-app"
  }
  service {
    name = "ALL"
  }
}
# ------------------------------------------------------------------------------------------
# GCP Define a new VIP resource
# ------------------------------------------------------------------------------------------
# Create VIP address votes APP
resource "fortios_firewall_vip" "gcp_app_vip_votes" {
  provider = fortios.gcp
  count    = contains(local.csps, "gcp") ? 1 : 0

  name = "vip-${local.fgt_values["gcp"]["MAPPED_IP"]}-${local.votes_nodeport}"

  type        = "static-nat"
  extintf     = "port1"
  extip       = local.fgt_values["gcp"]["EXTERNAL_IP"]
  extport     = local.votes_nodeport
  mappedport  = local.votes_nodeport
  portforward = "enable"

  mappedip {
    range = local.fgt_values["gcp"]["MAPPED_IP"]
  }
}
# Create VIP address results APP
resource "fortios_firewall_vip" "gcp_app_vip_results" {
  provider = fortios.gcp
  count    = contains(local.csps, "gcp") ? 1 : 0

  name = "vip-${local.fgt_values["gcp"]["MAPPED_IP"]}-${local.results_nodeport}"

  type        = "static-nat"
  extintf     = "port1"
  extip       = local.fgt_values["gcp"]["EXTERNAL_IP"]
  extport     = local.results_nodeport
  mappedport  = local.results_nodeport
  portforward = "enable"

  mappedip {
    range = local.fgt_values["gcp"]["MAPPED_IP"]
  }
}
# Create group of VIPs
resource "fortios_firewall_vipgrp" "gcp_app_vipgrp" {
  provider = fortios.gcp
  count    = contains(local.csps, "gcp") ? 1 : 0

  interface = "port1"
  name      = "vipgrp-${local.fgt_values["gcp"]["MAPPED_IP"]}-app"

  member {
    name = element(fortios_firewall_vip.gcp_app_vip_votes, 0).name
  }
  member {
    name = element(fortios_firewall_vip.gcp_app_vip_results, 0).name
  }
}
# Define a new firewall policy with default intrusion prevention profile
resource "fortios_firewall_policy" "gcp_app_policy" {
  provider   = fortios.gcp
  depends_on = [fortios_firewall_vipgrp.gcp_app_vipgrp]
  count      = contains(local.csps, "gcp") ? 1 : 0

  name = "vip-${local.fgt_values["gcp"]["EXTERNAL_IP"]}-vote-app"

  schedule        = "always"
  action          = "accept"
  utm_status      = "enable"
  ips_sensor      = "all_default_pass"
  ssl_ssh_profile = "certificate-inspection"
  nat             = "enable"
  logtraffic      = "all"

  dstintf {
    name = "port2"
  }
  srcintf {
    name = "port1"
  }
  srcaddr {
    name = "all"
  }
  dstaddr {
    name = "vipgrp-${local.fgt_values["gcp"]["MAPPED_IP"]}-app"
  }
  service {
    name = "ALL"
  }
}
*/