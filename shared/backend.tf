terraform {
 backend "s3" {
    key            = "terraform-state/shared/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
