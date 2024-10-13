// Get Ubuntu images
data "oci_core_images" "vm_image" {
  compartment_id           = var.compartment_ocid
  shape                    = var.shape
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
}
// Get AD in compartment region
data "oci_identity_availability_domains" "region_ads" {
  compartment_id = var.compartment_ocid
}
// Create instance
resource "oci_core_instance" "vm" {
  display_name        = var.prefix
  availability_domain = data.oci_identity_availability_domains.region_ads.availability_domains[var.region_ad].name
  compartment_id      = var.compartment_ocid
  shape               = var.shape
  shape_config {
    memory_in_gbs = var.memory_in_gbs
    ocpus         = var.ocpus
  }
  source_details {
    source_id   = data.oci_core_images.vm_image.images[0].id
    source_type = "image"
  }
  create_vnic_details {
    subnet_id        = var.subnet_id
    display_name     = var.prefix
    assign_public_ip = true
    hostname_label   = var.prefix
    private_ip       = var.private_ip != null ? var.private_ip : cidrhost(var.subnet_cidr, 10)
    nsg_ids          = var.nsg_ids
  }
  metadata = {
    ssh_authorized_keys = join("\n", var.authorized_keys)
    user_data           = var.user_data != null ? base64encode(var.user_data) : base64encode(file("${path.module}/templates/user-data.tpl"))
  }
}