output "fgt_id" {
  value = oci_core_instance.fgt.id
}
output "fgt_public_ip_public" {
  value = oci_core_instance.fgt.public_ip
}
output "fgt_vcn_rt_to_fgt_id" {
  value = oci_core_route_table.rt_to_fgt.id
}