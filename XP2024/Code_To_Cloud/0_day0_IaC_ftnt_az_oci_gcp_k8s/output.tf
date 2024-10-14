#------------------------------------------------------------------------------
# FGT clusters
#------------------------------------------------------------------------------
output "azure_fgt" {
  value = {
    username     = local.fgt_admin["azure"]
    fgt-1_pass   = local.fgt_password["azure"]
    fgt-1_mgmt   = "https://${module.azure_fgt_vnet.fgt-active-mgmt-ip}:${local.fgt_admin_port}"
    fgt-1_public = module.azure_xlb.elb_public-ip
    api_key      = trimspace(random_string.api_key.result)
  }
}
output "oci_fgt" {
  value = {
    fgt-1_mgmt   = "https://${module.oci_fgt.fgt_public_ip_public}:${local.fgt_admin_port}"
    username     = "admin"
    fgt-1_pass   = module.oci_fgt.fgt_id
    fgt-1_public = module.oci_fgt.fgt_public_ip_public
    api_key      = trimspace(random_string.api_key.result)
  }
}
output "gcp_fgt_office" {
  value = {
    fgt-1_mgmt   = "https://${module.gcp_fgt_office.fgt_eip_public}:${local.fgt_admin_port}"
    username     = "admin"
    fgt-1_pass   = module.gcp_fgt_office.fgt_id
    fgt-1_public = module.gcp_fgt_office.fgt_eip_public
    api_key      = trimspace(random_string.api_key.result)
  }
}
output "hubs_sdwan_details" {
  sensitive = true
  value     = local.hubs
}
output "hub_sdwan_details" {
  sensitive = true
  value     = local.hub
}

#------------------------------------------------------------------------------
# Kubernetes cluster export config
#------------------------------------------------------------------------------
output "kubectl_config" {
  value = {
    azure = {
      command_1 = "export KUBE_HOST=${local.master_public_ip["azure"]}:${local.api_port}"
      command_2 = "export KUBE_TOKEN=$(redis-cli -h ${local.db_host_public_ip["azure"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["azure"]}_cicd-access_token)"
      command_3 = "redis-cli -h ${local.db_host_public_ip["azure"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["azure"]}_master_ca_cert | base64 --decode >${local.db_prefix["azure"]}_ca.crt"
      command_4 = "kubectl get nodes --token $KUBE_TOKEN -s https://$KUBE_HOST --certificate-authority ${local.db_prefix["azure"]}_ca.crt"
    }
    oci = {
      command_1 = "export KUBE_HOST=${local.master_public_ip["oci"]}:${local.api_port}"
      command_2 = "export KUBE_TOKEN=$(redis-cli -h ${local.db_host_public_ip["oci"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["oci"]}_cicd-access_token)"
      command_3 = "redis-cli -h ${local.db_host_public_ip["oci"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["oci"]}_master_ca_cert | base64 --decode >${local.db_prefix["oci"]}_ca.crt"
      command_4 = "kubectl get nodes --token $KUBE_TOKEN -s https://$KUBE_HOST --certificate-authority ${local.db_prefix["oci"]}_ca.crt"
    }
  }
}
#------------------------------------------------------------------------------
# Kubernetes cluster nodes
#------------------------------------------------------------------------------
output "azure_node_master" {
  value = module.azure_node_master.vm
}
output "oci_node_master" {
  value = module.oci_node_master.vm
}

#------------------------------------------------------------------------------
# Office VM bastion
#------------------------------------------------------------------------------
output "gcp_office_vm" {
  value = module.gcp_office_vm.vm
}
#------------------------------------------------------------------------------
# FMG and FAZ
#------------------------------------------------------------------------------
output "faz" {
  value = {
    faz_mgmt = "https://${module.faz.faz_public_ip}"
    faz_pass = module.faz.faz_id
  }
}

#------------------------------------------------------------------------------
# FGT details 
#------------------------------------------------------------------------------
# FGT values
output "fgt_values" {
  sensitive = true
  value = {
    azure = {
      HOST        = "${module.azure_fgt_vnet.fgt-active-mgmt-ip}:${local.fgt_admin_port}"
      PUBLIC_IP   = module.azure_xlb.elb_public-ip
      EXTERNAL_IP = module.azure_fgt_vnet.fgt-active-ni_ips["public"]
      MAPPED_IP   = module.azure_node_master.vm["private_ip"]
      TOKEN       = trimspace(random_string.api_key.result)
    }
    oci = {
      HOST        = "${module.oci_fgt.fgt_public_ip_public}:${local.fgt_admin_port}"
      PUBLIC_IP   = module.oci_fgt.fgt_public_ip_public
      EXTERNAL_IP = module.oci_fgt_vcn.fgt_ni_ips["public"]
      MAPPED_IP   = module.oci_node_master.vm["private_ip"]
      TOKEN       = trimspace(random_string.api_key.result)
    }
  }
}
#-----------------------------------------------------------------------------------------------------
# K8S Clusters (CLI commands to retrieve data from redis)
#-----------------------------------------------------------------------------------------------------
# Commands to get K8S clusters variables
output "k8s_values_cli" {
  sensitive = true
  value = {
    azure = {
      KUBE_TOKEN       = "redis-cli -h ${local.db_host_public_ip["azure"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["azure"]}_cicd-access_token"
      KUBE_HOST        = "echo ${local.master_public_ip["azure"]}:${local.api_port}"
      KUBE_CERTIFICATE = "redis-cli -h ${local.db_host_public_ip["azure"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["azure"]}_master_ca_cert"
    }
    oci = {
      KUBE_TOKEN       = "redis-cli -h ${local.db_host_public_ip["oci"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["oci"]}_cicd-access_token"
      KUBE_HOST        = "echo ${local.master_public_ip["oci"]}:${local.api_port}"
      KUBE_CERTIFICATE = "redis-cli -h ${local.db_host_public_ip["oci"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["oci"]}_master_ca_cert"
    }
  }
}

#-----------------------------------------------------------------------------------------------------
# OLD
#-----------------------------------------------------------------------------------------------------
/*
output "fmg" {
  value = {
    fmg_mgmt = "https://${module.fmg.eip_public}"
    fmg_pass = module.fmg.id
  }
}

output "azure_node_worker" {
  value = module.azure_node_worker.*.vm
}
output "oci_node_worker" {
  value = module.oci_node_worker.*.vm
}
*/