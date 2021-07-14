terraform {
  backend "s3" {
    key            = "terraform-state/mill/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
