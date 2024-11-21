module "network_secret_ro" {
  source    = "../modules/sm-reader"
  secret_id = "${terraform.workspace}/core-infra-secrets"
}

data "aws_region" "current" {}


locals {
  az_suffix = ["a", "b", "c", "d", "e", "f"]

  # Core Component Configurations.
  core_name_prefix = "${terraform.workspace}.core"
  core_az_count    = module.network_secret_ro.secret_map["core_az_count"]
  core_vpc_cidr    = module.network_secret_ro.secret_map["core_vpc_cidr"]
  project_name     = "cloud-deep-dive"
  core_region      = data.aws_region.current.name
}
