resource "aws_ecr_repository" "backend_repos" {
  name                 = "${terraform.workspace}-backend-repo"
  image_tag_mutability = "MUTABLE"

  force_delete = true
  
  image_scanning_configuration {
    scan_on_push = true
  }
}