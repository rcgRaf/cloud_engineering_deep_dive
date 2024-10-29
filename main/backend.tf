terraform {
  backend "s3" {
    bucket         = "rcgrafbucket"
    dynamodb_table = "rcgraf-terraform-state"
    encrypt        = true
    key            = "projects/aca-terraform-states-main.tfstate"
    region         = "us-east-1"
  }
}