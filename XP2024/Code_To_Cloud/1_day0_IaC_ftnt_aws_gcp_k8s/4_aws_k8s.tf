#--------------------------------------------------------------------------
# Create cluster nodes: master and workers
#--------------------------------------------------------------------------
// Create VPC Nodes K8S attached to TGW
module "aws_nodes_vpc" {
  source = "./modules/aws_vpc_spoke_tgw"

  prefix     = "${local.prefix}-nodes"
  admin_cidr = local.fgt_admin_cidr
  admin_port = local.fgt_admin_port
  region     = local.aws_region

  vpc-spoke_cidr = local.nodes_cidr["aws"]

  tgw_id                = module.tgw.tgw_id
  tgw_rt-association_id = module.tgw.rt_vpc-spoke_id
  tgw_rt-propagation_id = [module.tgw.rt_default_id, module.tgw.rt-vpc-sec-N-S_id, module.tgw.rt-vpc-sec-E-W_id]
}
// Create static route in TGW RouteTable Spoke
resource "aws_ec2_transit_gateway_route" "nodes_tgw_route" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.aws_fgt_vpc.vpc_tgw-att_id
  transit_gateway_route_table_id = module.tgw.rt_vpc-spoke_id
}
# Create NI for node master
resource "aws_network_interface" "aws_node_master_ni" {
  subnet_id         = local.aws_nodes_subnet_id
  security_groups   = [local.aws_nodes_sg_id]
  private_ips       = [local.master_ip["aws"]]
  source_dest_check = false
  tags = {
    Name = "${local.prefix}-ni-node-master"
  }
}
# Create EIP active public NI for node master
resource "aws_eip" "aws_node_master_eip" {
  domain            = "vpc"
  network_interface = aws_network_interface.aws_node_master_ni.id
  tags = {
    Name = "${local.prefix}-eip-node-master"
  }
}
# Deploy cluster master node
module "aws_node_master" {
  source = "./modules/aws_new_vm_ni"

  prefix  = "${local.prefix}-master"
  keypair = aws_key_pair.keypair.key_name

  instance_type = local.node_instance_type["aws"]
  disk_size     = local.disk_size
  user_data     = data.template_file.aws_node_master.rendered

  ni_id = aws_network_interface.aws_node_master_ni.id
}

# Create data template for master node
data "template_file" "aws_node_master" {
  template = file("./templates/k8s-master.sh")
  vars = {
    cert_extra_sans = local.master_public_ip["aws"]
    script          = data.template_file.aws_node_master_script.rendered
    k8s_version     = local.k8s_version
    lacework_k8s    = data.template_file.lacework_k8s_yaml.rendered
    db_pass         = local.db_pass
    linux_user      = local.linux_user["aws"]
  }
}
data "template_file" "aws_node_master_script" {
  template = file("./templates/export-k8s-cluster-info.py")
  vars = {
    db_host         = local.db_host["aws"]
    db_port         = local.db_port
    db_pass         = local.db_pass
    db_prefix       = local.db_prefix["aws"]
    master_ip       = local.master_ip["aws"]
    master_api_port = local.api_port
  }
}
data "template_file" "lacework_k8s_yaml" {
  template = file("./templates/lacework-k8s.yaml")
  vars = {
    token      = var.lacework_agent["token"]
    server_url = var.lacework_agent["server_url"]
  }
}

/*
# Create EIP active public NI for node worker
resource "aws_eip" "aws_node_worker_eip" {
  count             = local.worker_number
  domain            = "vpc"
  network_interface = aws_network_interface.aws_node_worker_ni[count.index].id
  tags = {
    Name = "${local.prefix}-eip-node-worker-${count.index + 1}"
  }
}
# Create NI for node worker
resource "aws_network_interface" "aws_node_worker_ni" {
  count             = local.worker_number
  subnet_id         = local.aws_nodes_subnet_id
  security_groups   = [local.aws_nodes_sg_id]
  private_ips       = [cidrhost(module.aws_nodes_vpc.subnet_az1_cidrs["vm"], local.node_master_cidrhost + count.index + 1)]
  source_dest_check = false
  tags = {
    Name = "${local.prefix}-ni-node-worker-${count.index + 1}"
  }
}
# Deploy cluster worker nodes
module "aws_node_worker" {
  depends_on = [module.aws_node_master]
  count      = local.worker_number
  source     = "git::github.com/jmvigueras/modules//aws/new-instance_ni"

  prefix  = "${local.prefix}-worker"
  suffix  = count.index + 1
  keypair = aws_key_pair.keypair.key_name

  instance_type = local.node_instance_type["aws"]
  disk_size     = local.disk_size
  user_data     = data.template_file.aws_node_worker.rendered

  ni_id = aws_network_interface.aws_node_worker_ni[count.index].id
}
# Create data template for worker node
data "template_file" "aws_node_worker" {
  template = file("./templates/k8s-worker.sh")
  vars = {
    script      = data.template_file.aws_node_worker_script.rendered
    k8s_version = local.k8s_version
  }
}
data "template_file" "aws_node_worker_script" {
  // depends_on = [module.fgt]
  template = file("./templates/join-k8s-cluster.py")
  vars = {
    db_host   = local.db_host["aws"]
    db_port   = local.db_port
    db_pass   = local.db_pass
    db_prefix = local.db_prefix["aws"]
  }
}
*/