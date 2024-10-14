locals {
  # ----------------------------------------------------------------------------------
  # Subnet cidrs (UPDATE IF NEEDED)
  # ----------------------------------------------------------------------------------
  subnet_public_cidr  = cidrsubnet(var.vcn_cidr, 2, 0)
  subnet_private_cidr = cidrsubnet(var.vcn_cidr, 2, 1)
  subnet_bastion_cidr = cidrsubnet(var.vcn_cidr, 2, 3)
  # ----------------------------------------------------------------------------------
  # FGT IP (UPDATE IF NEEDED)
  # ----------------------------------------------------------------------------------
  fgt_ni_public_ip  = cidrhost(local.subnet_public_cidr, 10)
  fgt_ni_private_ip = cidrhost(local.subnet_private_cidr, 10)
  # ----------------------------------------------------------------------------------
  # iLB
  # ----------------------------------------------------------------------------------
  ilb_ip = cidrhost(local.subnet_private_cidr, 9)
  # ----------------------------------------------------------------------------------
  # Bastion VM
  # ----------------------------------------------------------------------------------
  bastion_ni_ip = cidrhost(local.subnet_bastion_cidr, 10)
}