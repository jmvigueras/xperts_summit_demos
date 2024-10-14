#---------------------------------------------------------------------------------------------------
# FGT-1 INSTANCE
# - FGT-1
# - Public VNIC
# - Private VNIC
#---------------------------------------------------------------------------------------------------
// Create FGT-1 instance
resource "oci_core_instance" "fgt" {
  availability_domain = data.oci_identity_availability_domain.ad_1.name
  compartment_id      = var.compartment_ocid
  display_name        = "${var.prefix}-fgt"
  shape               = var.instance_shape
  
  shape_config {
    memory_in_gbs = var.memory_in_gbs
    ocpus         = var.ocpus
  }

  create_vnic_details {
    subnet_id        = var.fgt_subnet_ids["public"]
    display_name     = "fgt-public"
    assign_public_ip = true
    hostname_label   = "fgt"
    private_ip       = var.fgt_ips["public"]
    nsg_ids          = [var.fgt_nsg_ids["public"]]
  }
  source_details {
    source_type = "image"
    source_id   = local.fgt_image_id
  }
  metadata = {
    // ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(var.fgt_config)
  }
  timeouts {
    create = "60m"
  }
}
#---------------------------------------------------------------------------------------------------
# - FGT-1 Private VNIC
#---------------------------------------------------------------------------------------------------
// FGT-1 private VNIC: create VNIC
resource "oci_core_vnic_attachment" "fgt_vnic_private" {
//  depends_on   = [oci_core_instance.fgt]
  instance_id  = oci_core_instance.fgt.id
  display_name = "fgt-private"

  create_vnic_details {
    subnet_id              = var.fgt_subnet_ids["private"]
    display_name           = "fgt-private"
    assign_public_ip       = false
    skip_source_dest_check = true
    private_ip             = var.fgt_ips["private"]
    nsg_ids                = [var.fgt_nsg_ids["private"]]
  }
}
// Get VNIC private ip ocid
data "oci_core_private_ips" "fgt_vnic_private" {
    subnet_id  = var.fgt_subnet_ids["private"]
    vnic_id    = oci_core_vnic_attachment.fgt_vnic_private.vnic_id
}
#---------------------------------------------------------------------------------------------------
# - FGT-1 Data Volume
#---------------------------------------------------------------------------------------------------
// Create volume
resource "oci_core_volume" "fgt_vol_a" {
  availability_domain = data.oci_identity_availability_domain.ad_1.name
  compartment_id      = var.compartment_ocid
  display_name        = "fgt-vol-a"
  size_in_gbs         = var.volume_size
}
// Attach volume
resource "oci_core_volume_attachment" "fgt_vol_a_attach" {
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.fgt.id
  volume_id       = oci_core_volume.fgt_vol_a.id
}