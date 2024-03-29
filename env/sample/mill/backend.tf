terraform {
  backend "s3" {
    bucket         = "<your bucket here>"
    profile        = "<your aws profile here>"
    region         = "<your aws region here>"
    key            = "terraform/duracloud/mill/tf-state"
    encrypt        = true
    dynamodb_table = "<your table here>"
  }
}

provider "aws" {
  profile = "<your aws profile here>"
  region  = "<your aws region here>"
}
