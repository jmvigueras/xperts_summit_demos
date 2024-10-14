#---------------------------------------------------------------------------
# Crate Route Tables
#---------------------------------------------------------------------------
# Route public
resource "aws_route_table" "rt-public" {
  vpc_id = aws_vpc.vpc-sec.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-vpc-sec.id
  }
  tags = {
    Name = "${var.prefix}-rt-public"
  }
}
# Route private
resource "aws_route_table" "rt-bastion" {
  vpc_id = aws_vpc.vpc-sec.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-vpc-sec.id
  }
  route {
    cidr_block           = "172.16.0.0/12"
    network_interface_id = aws_network_interface.ni-private.id
  }
  route {
    cidr_block           = "192.168.0.0/16"
    network_interface_id = aws_network_interface.ni-private.id
  }
  route {
    cidr_block           = "10.0.0.0/8"
    network_interface_id = aws_network_interface.ni-private.id
  }
  tags = {
    Name = "${var.prefix}-rt-bastion"
  }
}
# Route tgw
resource "aws_route_table" "rt-tgw" {
  vpc_id = aws_vpc.vpc-sec.id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_network_interface.ni-private.id
  }

  tags = {
    Name = "${var.prefix}-rt-tgw"
  }
}
# Route tables associations AZ1
resource "aws_route_table_association" "ra-subnet-az1-public" {
  subnet_id      = aws_subnet.subnet-az1-public.id
  route_table_id = aws_route_table.rt-public.id
}
resource "aws_route_table_association" "ra-subnet-az1-tgw" {
  subnet_id      = aws_subnet.subnet-az1-tgw.id
  route_table_id = aws_route_table.rt-tgw.id
}
resource "aws_route_table_association" "ra-subnet-az1-bastion" {
  subnet_id      = aws_subnet.subnet-az1-bastion.id
  route_table_id = aws_route_table.rt-bastion.id
}
#---------------------------------------------------------------------------
# Route subnet private (FGT)
# - Create TGW attachment
# - Associate to RT
# - Propagate to RT
#---------------------------------------------------------------------------
# Attachment to TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-att-vpc-sec" {
  subnet_ids             = [aws_subnet.subnet-az1-tgw.id]
  transit_gateway_id     = var.tgw_id
  vpc_id                 = aws_vpc.vpc-sec.id
  appliance_mode_support = "enable"

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "${var.prefix}-tgw-att-vpc-sec"
  }
}
# Create route table association
resource "aws_ec2_transit_gateway_route_table_association" "tgw-att-vpc-sec_association" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-sec.id
  transit_gateway_route_table_id = var.tgw_rt-association_id
}
# Create route propagation if route table id provided
resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-att-vpc-sec_propagation" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-sec.id
  transit_gateway_route_table_id = var.tgw_rt-propagation_id
}
# Create RouteTable private to TGW
resource "aws_route_table" "rt-private" {
  vpc_id = aws_vpc.vpc-sec.id
  route {
    cidr_block         = "172.16.0.0/12"
    transit_gateway_id = var.tgw_id
  }
  route {
    cidr_block         = "192.168.0.0/16"
    transit_gateway_id = var.tgw_id
  }
  route {
    cidr_block         = "10.0.0.0/8"
    transit_gateway_id = var.tgw_id
  }
  tags = {
    Name = "${var.prefix}-rt-private"
  }
}
# Associate to private subnet
resource "aws_route_table_association" "ra-subnet-az1-private" {
  subnet_id      = aws_subnet.subnet-az1-private.id
  route_table_id = aws_route_table.rt-private.id
}