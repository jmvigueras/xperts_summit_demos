#------------------------------------------------------------------------------------------------------------
# Create cluster nodes: master and workers
#------------------------------------------------------------------------------------------------------------
// Create spoke VCN and attached to DRG
module "oci_nodes_vcn" {
  source = "./modules/oci_vcn_spoke_peer"

  compartment_ocid = var.compartment_ocid
  prefix           = local.prefix

  admin_cidr     = local.fgt_admin_cidr
  vcn_cidr       = local.nodes_cidr["oci"]
  fgt_vcn_lpg_id = module.oci_fgt_lpg.fgt_vcn_lpg_id
}
// Deploy cluster master node
module "oci_node_master" {
  source = "./modules/oci_new_vm"

  compartment_ocid = var.compartment_ocid
  prefix           = "${local.prefix}-master"

  ocpus         = 2
  memory_in_gbs = 8

  user_data       = data.template_file.oci_node_master.rendered
  private_ip      = cidrhost(local.nodes_cidr["oci"], local.node_master_cidrhost)
  subnet_id       = module.oci_nodes_vcn.subnet_ids["vm"]
  authorized_keys = [chomp(tls_private_key.ssh.public_key_openssh)]
}
# Create data template for master node
data "template_file" "oci_node_master" {
  template = file("./templates/k8s-master.sh")
  vars = {
    cert_extra_sans = local.master_public_ip["oci"]
    script          = data.template_file.oci_node_master_script.rendered
    k8s_version     = local.k8s_version
    lacework_k8s    = data.template_file.lacework_k8s_yaml.rendered
    db_pass         = local.db_pass
    linux_user      = local.linux_user["oci"]
  }
}
data "template_file" "oci_node_master_script" {
  template = file("./templates/export-k8s-cluster-info.py")
  vars = {
    db_host         = local.db_host["oci"]
    db_port         = local.db_port
    db_pass         = local.db_pass
    db_prefix       = local.db_prefix["oci"]
    master_ip       = local.master_ip["oci"]
    master_api_port = local.api_port
  }
}