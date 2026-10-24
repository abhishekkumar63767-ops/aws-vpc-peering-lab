# Missing Route in VPC A Public Route Table (ewb-rt-a-public)
# Required for Bastion OpenSSH ProxyJump to reach App-B in VPC B via peering
resource "aws_route" "public_subnet_to_vpc_b_peering" {
  route_table_id            = var.route_table_a_public_id
  destination_cidr_block    = data.aws_vpc.vpc_b.cidr_block
  vpc_peering_connection_id = var.peering_connection_id
}
