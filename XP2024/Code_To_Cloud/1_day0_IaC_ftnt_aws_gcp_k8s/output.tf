#------------------------------------------------------------------------------
# FGT clusters
#------------------------------------------------------------------------------
output "gcp_fgt" {
  value = {
    fgt-1_mgmt   = "https://${module.gcp_fgt.fgt_eip_public}:${local.fgt_admin_port}"
    username     = "admin"
    fgt-1_pass   = module.gcp_fgt.fgt_id
    fgt-1_public = module.gcp_fgt.fgt_eip_public
    api_key      = trimspace(random_string.api_key.result)
  }
}
output "aws_fgt" {
  value = {
    fgt-1_mgmt   = "https://${module.aws_fgt.fgt_eip_public}:${local.fgt_admin_port}"
    username     = "admin"
    fgt-1_pass   = module.aws_fgt.fgt_id
    fgt-1_public = module.aws_fgt.fgt_eip_public
    api_key      = trimspace(random_string.api_key.result)
  }
}
#------------------------------------------------------------------------------
# Kubernetes cluster export config
#------------------------------------------------------------------------------
output "kubectl_config" {
  value = {
    gcp = {
      command_1 = "export KUBE_HOST=${local.master_public_ip["gcp"]}:${local.api_port}"
      command_2 = "export KUBE_TOKEN=$(redis-cli -h ${local.db_host_public_ip["gcp"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["gcp"]}_cicd-access_token)"
      command_3 = "redis-cli -h ${local.db_host_public_ip["gcp"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["gcp"]}_master_ca_cert | base64 --decode >${local.db_prefix["gcp"]}_ca.crt"
      command_4 = "kubectl get nodes --token $KUBE_TOKEN -s https://$KUBE_HOST --certificate-authority ${local.db_prefix["gcp"]}_ca.crt"
    }
    aws = {
      command_1 = "export KUBE_HOST=${local.master_public_ip["aws"]}:${local.api_port}"
      command_2 = "export KUBE_TOKEN=$(redis-cli -h ${local.db_host_public_ip["aws"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["aws"]}_cicd-access_token)"
      command_3 = "redis-cli -h ${local.db_host_public_ip["aws"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["aws"]}_master_ca_cert | base64 --decode >${local.db_prefix["aws"]}_ca.crt"
      command_4 = "kubectl get nodes --token $KUBE_TOKEN -s https://$KUBE_HOST --certificate-authority ${local.db_prefix["aws"]}_ca.crt"
    }
  }
}
#------------------------------------------------------------------------------
# Kubernetes cluster nodes
#------------------------------------------------------------------------------
output "gcp_node_master" {
  value = module.gcp_node_master.vm
}
output "aws_node_master" {
  value = module.aws_node_master.vm
}
/*
output "gcp_node_worker" {
  value = module.gcp_node_worker.*.vm
}
output "aws_node_worker" {
  value = module.aws_node_worker.*.vm
}
*/
#------------------------------------------------------------------------------
# FGT APP details 
#------------------------------------------------------------------------------
# FGT values
output "fgt_values" {
  sensitive = true
  value = {
    gcp = {
      HOST        = "${module.gcp_fgt.fgt_eip_public}:${local.fgt_admin_port}"
      PUBLIC_IP   = module.gcp_fgt.fgt_eip_public
      EXTERNAL_IP = module.gcp_fgt_vpc.fgt_ni_ips["public"]
      MAPPED_IP   = module.gcp_node_master.vm["private_ip"]
      TOKEN       = trimspace(random_string.api_key.result)
    }
    aws = {
      HOST        = "${module.aws_fgt.fgt_eip_public}:${local.fgt_admin_port}"
      PUBLIC_IP   = module.aws_fgt.fgt_eip_public
      EXTERNAL_IP = module.aws_fgt_vpc.fgt_ni_ips["public"]
      MAPPED_IP   = module.aws_node_master.vm["private_ip"]
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
    gcp = {
      KUBE_TOKEN       = "redis-cli -h ${local.db_host_public_ip["gcp"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["gcp"]}_cicd-access_token"
      KUBE_HOST        = "echo ${local.master_public_ip["gcp"]}:${local.api_port}"
      KUBE_CERTIFICATE = "redis-cli -h ${local.db_host_public_ip["gcp"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["gcp"]}_master_ca_cert"
    }
    aws = {
      KUBE_TOKEN       = "redis-cli -h ${local.db_host_public_ip["aws"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["aws"]}_cicd-access_token"
      KUBE_HOST        = "echo ${local.master_public_ip["aws"]}:${local.api_port}"
      KUBE_CERTIFICATE = "redis-cli -h ${local.db_host_public_ip["aws"]} -p ${local.db_port} -a ${local.db_pass} --no-auth-warning GET ${local.db_prefix["aws"]}_master_ca_cert"
    }
  }
}

