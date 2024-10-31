resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "${local.prefix}-vpc"
  }
}

resource "aws_subnet" "main" {
  count             = local.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(local.vpc_cidr, 8, count.index)
  availability_zone = "${local.region}${local.az_suffix[count.index]}"

  tags = {
    Name = "${local.prefix}-subnet-private-${local.az_suffix[count.index]}"
  }
}


resource "aws_route_table" "main" {
  count  = local.az_count
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-private-rt-${local.az_suffix[count.index]}"
  }
}

resource "aws_route_table_association" "main" {
  count          = local.az_count
  subnet_id      = aws_subnet.main[count.index].id
  route_table_id = aws_route_table.main[count.index].id
}



# resource "aws_ec2_transit_gateway" "main" {
#   description                     = "${local.prefix} transit gateway"
#   default_route_table_association = "disable"
#   default_route_table_propagation = "disable"
#   tags = {
#     Name = "${local.prefix}-tgw"
#   }
# }


# resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
#   subnet_ids         = aws_subnet.main[*].id
#   transit_gateway_id = aws_ec2_transit_gateway.main.id
#   vpc_id             = aws_vpc.main.id
#   tags = {
#     Name = "${local.prefix}-tgw-attachment"
#   }
# }


# resource "aws_ec2_transit_gateway_vpc_attachment" "project_vpcs" {
#   for_each = toset(local.core_workspaces)

#   transit_gateway_id = aws_ec2_transit_gateway.main.id
#   vpc_id             = local.core_vpc_ids[each.key]
#   subnet_ids         = local.core_private_subnet_ids[each.key]

#   tags = {
#     Name = "${local.prefix}-tgw-${each.key}-attachment"
#   }
# }



resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-igw"
  }
}

resource "aws_route" "main_internet_access" {
  count                  = local.az_count
  route_table_id         = aws_route_table.main[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}




# New security group for OpenVPN EC2 instance
# resource "aws_security_group" "openvpn" {
#   name        = "${local.prefix}-openvpn-sg"
#   description = "Security group for OpenVPN EC2 instance"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     from_port   = 1194
#     to_port     = 1194
#     protocol    = "udp"
#     cidr_blocks = ["0.0.0.0/0"] # Allow OpenVPN connections from anywhere
#   }

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # Replace with your admin IP for SSH access
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "${local.prefix}-openvpn-sg"
#   }
# }

# Add route for VPN clients (10.20.0.0/24) to each private subnet's route table
# resource "aws_route" "vpn_clients" {
#   count                  = local.az_count
#   route_table_id         = aws_route_table.main[count.index].id
#   destination_cidr_block = local.vpn_cidr
#   network_interface_id   = aws_instance.openvpn_server.primary_network_interface_id
# }

# Add routes to the Transit Gateway for other VPCs
# resource "aws_route" "to_other_vpcs" {
#   count                  = local.az_count
#   route_table_id         = aws_route_table.main[count.index].id
#   destination_cidr_block = local.vpc_space_cidr
#   transit_gateway_id     = aws_ec2_transit_gateway.main.id
# }

# Transit Gateway Route Table
# resource "aws_ec2_transit_gateway_route_table" "main" {
#   transit_gateway_id = aws_ec2_transit_gateway.main.id

#   tags = {
#     Name = "${local.prefix}-tgw-rt"
#   }
# }

# Route in Transit Gateway Route Table for VPN clients
# resource "aws_ec2_transit_gateway_route" "vpn_clients" {
#   destination_cidr_block         = local.vpn_cidr
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.main.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
# }

# Associate the Transit Gateway Route Table with VPC attachments
# resource "aws_ec2_transit_gateway_route_table_association" "main" {
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.main.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
# }

# resource "aws_ec2_transit_gateway_route_table_association" "project_vpcs" {
#   for_each = toset(local.core_workspaces)

#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.project_vpcs[each.key].id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
# }

# Propagate routes from VPC attachments to the Transit Gateway Route Table
# resource "aws_ec2_transit_gateway_route_table_propagation" "main" {
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.main.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
# }

# resource "aws_ec2_transit_gateway_route_table_propagation" "project_vpcs" {
#   for_each = toset(local.core_workspaces)

#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.project_vpcs[each.key].id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
# }



# resource "aws_route" "from_core_private_to_vpn_clients" {
#   count                  = length(local.flattened_core_route_tables)
#   route_table_id         = local.flattened_core_route_tables[count.index].rt_id
#   destination_cidr_block = local.vpn_cidr
#   transit_gateway_id     = aws_ec2_transit_gateway.main.id
# }

# resource "aws_route" "from_core_private_to_openvpn_vpc" {
#   count                  = length(local.flattened_core_route_tables)
#   route_table_id         = local.flattened_core_route_tables[count.index].rt_id
#   destination_cidr_block = aws_vpc.main.cidr_block
#   transit_gateway_id     = aws_ec2_transit_gateway.main.id
# }



# resource "aws_route" "from_core_public_to_vpn_clients" {
#   for_each               = toset(local.core_workspaces)
#   route_table_id         = local.core_public_route_table_id[each.key]
#   destination_cidr_block = local.vpn_cidr
#   transit_gateway_id     = aws_ec2_transit_gateway.main.id
# }

# resource "aws_route" "to_openvpn_vpc" {
#   for_each               = toset(local.core_workspaces)
#   route_table_id         = local.core_public_route_table_id[each.key]
#   destination_cidr_block = aws_vpc.main.cidr_block
#   transit_gateway_id     = aws_ec2_transit_gateway.main.id
# }
