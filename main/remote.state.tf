data "terraform_remote_state" "projects" {
  for_each = toset(local.core_workspaces)
  backend  = "s3"
  config = {
    bucket               = "rcgrafbucket"
    key                  = "projects/terraform-states-core.tfstate"
    region               = "us-east-1"
    workspace_key_prefix = "env:"
  }
  workspace = each.key
}
