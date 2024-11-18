terraform {
  backend "s3" {
    bucket         = "rcgrafbucket"
    dynamodb_table = "rcgraf-terraform-state"
    encrypt        = true
    key            = "projects/terraform-states-core.tfstate"
    region         = "us-east-1"
  }
}