output "vm" {
  value = {
    id         = oci_core_instance.vm.id
    public_ip  = oci_core_instance.vm.public_ip
    private_ip = var.private_ip != null ? var.private_ip : cidrhost(var.subnet_cidr, 10)
  }
}


