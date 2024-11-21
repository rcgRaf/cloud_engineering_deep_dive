# module "network_secret_ro" {
#   source    = "../modules/sm-reader"
#   secret_id = "main/infra-secrets"
# }


# data "aws_region" "current" {}
# data "aws_caller_identity" "current" {}


# locals {
#   az_suffix = ["a", "b", "c", "d", "e", "f"]

#   # Main Component Configurations.
#   prefix              = "${terraform.workspace}-hub"
#   region              = data.aws_region.current.name
#   az_count            = module.network_secret_ro.secret_map["az_count"]
#   vpc_cidr            = module.network_secret_ro.secret_map["vpc_cidr"]
#   vpn_cidr            = "10.20.0.0/24"
#   vpc_space_cidr      = module.network_secret_ro.secret_map["vpc_space_cidr"]
#   github_token        = module.network_secret_ro.secret_map["github_token"]
#   repo_url            = module.network_secret_ro.secret_map["repo_url"]
#   runner_label        = "main-runner"
#   openvpn_public_key  = file("${path.module}/pub_keys/dev_core_instance_access.pub")
#   github_public_key   = file("${path.module}/pub_keys/dev_core_instance_access.pub")
#   ec2_runner_iam_role = module.network_secret_ro.secret_map["ec2_runner_iam_role"]
#   github_org          = module.network_secret_ro.secret_map["github_org"]
#   github_repo_name    = module.network_secret_ro.secret_map["github_repo_name"]

#   # Core Component Configurations.
#   core_workspaces = jsondecode(module.network_secret_ro.secret_map["core_workspaces"])
#   core_vpc_ids = {
#     for workspace, state in data.terraform_remote_state.projects :
#     workspace => state.outputs.vpc_id
#   }
#   core_private_subnet_ids = {
#     for workspace, state in data.terraform_remote_state.projects :
#     workspace => state.outputs.private_subnet_ids
#   }
#   core_public_subnet_ids = {
#     for workspace, state in data.terraform_remote_state.projects :
#     workspace => state.outputs.public_subnet_ids
#   }
#   core_vpc_cidrs = {
#     for workspace, state in data.terraform_remote_state.projects :
#     workspace => state.outputs.vpc_cidr
#   }
#   core_availability_zones = {
#     for workspace, state in data.terraform_remote_state.projects :
#     workspace => state.outputs.availability_zones
#   }
#   core_public_route_table_id = {
#     for workspace, state in data.terraform_remote_state.projects :
#     workspace => state.outputs.public_route_table_id
#   }
#   core_private_route_table_ids = {
#     for workspace, state in data.terraform_remote_state.projects :
#     workspace => state.outputs.private_route_table_ids
#   }


#   flattened_core_route_tables = flatten([
#     for workspace, route_tables in local.core_private_route_table_ids : [
#       for rt_id in route_tables : {
#         workspace = workspace
#         rt_id     = rt_id
#       }
#     ]
#   ])
# }