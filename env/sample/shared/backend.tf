terraform {
  backend "s3" {
    bucket         = "<your bucket here>"
    profile        = "<your aws profile here>"
    region         = "<your aws region here>"
    key            = "terraform/duracloud/shared/tf-state"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}

provider "aws" {
  profile    = "<your aws profile here>"
  region     = "<your aws region here>"
}
