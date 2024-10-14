#----------------------------------------------------------------------------------------
# NSG
# - MGMT 
# - Public 
# - Private
# - Bastion
#----------------------------------------------------------------------------------------
#
#----------------------------------------------------------------------------------------
# - Public NSG
#----------------------------------------------------------------------------------------
// Network Security Group
resource "oci_core_network_security_group" "nsg_public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "${var.prefix}-nsg-public"
}
// Security list
resource "oci_core_network_security_group_security_rule" "nsg_sl_public_1" {
  network_security_group_id = oci_core_network_security_group.nsg_public.id
  
  description = "Allow all"
  direction   = "INGRESS"
  source_type = "CIDR_BLOCK"
  protocol    = "all"
  source      = "0.0.0.0/0"
}
#----------------------------------------------------------------------------------------
# - Private Security list
#----------------------------------------------------------------------------------------
// Network Security Group
resource "oci_core_network_security_group" "nsg_private" {
    compartment_id = var.compartment_ocid
    vcn_id         = oci_core_virtual_network.vcn.id
    display_name   = "${var.prefix}-nsg-private"
}
// Security list
resource "oci_core_network_security_group_security_rule" "nsg_sl_private_1" {
  network_security_group_id = oci_core_network_security_group.nsg_private.id
  
  description = "Allow all"
  direction   = "INGRESS"
  source_type = "CIDR_BLOCK"
  protocol    = "all"
  source      = "0.0.0.0/0"
}
#----------------------------------------------------------------------------------------
# - Bastion NSG
#----------------------------------------------------------------------------------------
// Network Security Group
resource "oci_core_network_security_group" "nsg_bastion" {
    compartment_id = var.compartment_ocid
    vcn_id         = oci_core_virtual_network.vcn.id
    display_name   = "${var.prefix}-nsg-bastion"
}
// Security list
resource "oci_core_network_security_group_security_rule" "nsg_bastion_1" {
  network_security_group_id = oci_core_network_security_group.nsg_bastion.id
  
  description = "Allow all"
  direction   = "INGRESS"
  source_type = "CIDR_BLOCK"
  protocol    = "all"
  source      = "0.0.0.0/0"
}

#----------------------------------------------------------------------------------------
# Security List
# - Public 
# - Private
# - Bastion
#----------------------------------------------------------------------------------------
#
#----------------------------------------------------------------------------------------
# - Public Security list
#----------------------------------------------------------------------------------------
resource "oci_core_security_list" "sl_public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "${var.prefix}-sl-public"

  // Allow all traffic ingress
  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
  }
  // Allow all traffic egress
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}
#----------------------------------------------------------------------------------------
# - Private Security list
#----------------------------------------------------------------------------------------
resource "oci_core_security_list" "sl_private" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "${var.prefix}-sl-private"

  // Allow all traffic ingress
  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
  }
  // Allow all traffic egress
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}
#----------------------------------------------------------------------------------------
# - Bastion Security List
#----------------------------------------------------------------------------------------
resource "oci_core_security_list" "sl_bastion" {
    compartment_id = var.compartment_ocid
    vcn_id         = oci_core_virtual_network.vcn.id
    display_name   = "${var.prefix}-sl-bastion"

  // Allow all traffic ingress
  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
  }
  // Allow all traffic egress
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}