output "fgt_vnics_ips" {
  value = {
    public  = local.fgt_ni_public_ip
    private = local.fgt_ni_private_ip
  }
}

output "fgt_ni_ips" {
  value = {
    public  = local.fgt_ni_public_ip
    private = local.fgt_ni_private_ip
  }
}

output "vcn_id" {
  value = oci_core_virtual_network.vcn.id 
}

output "subnet_ids" {
  value = {
    public  = oci_core_subnet.subnet_public.id
    private = oci_core_subnet.subnet_private.id
    bastion = oci_core_subnet.subnet_bastion.id
  }
}

output "subnet_cidrs" {
  value = {
    public  = local.subnet_public_cidr
    private = local.subnet_private_cidr
    bastion = local.subnet_bastion_cidr
  }
}

output "nsg_ids" {
  value = {
    public  = oci_core_network_security_group.nsg_public.id
    private = oci_core_network_security_group.nsg_private.id
    bastion = oci_core_network_security_group.nsg_bastion.id
  }
}