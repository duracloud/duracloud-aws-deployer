terraform {
 backend "s3" {
    key            = "terraform-state/management-console/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
