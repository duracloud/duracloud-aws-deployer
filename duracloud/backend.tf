terraform {
 backend "s3" {
    key            = "terraform-state/duracloud/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
