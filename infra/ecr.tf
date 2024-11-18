resource "aws_ecr_repository" "backend_repos" {
  name                 = "${terraform.workspace}-backend-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}