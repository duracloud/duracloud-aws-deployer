# TERRAFORM BACKEND & PROVIDER CFG
terraform {
  required_version = "1.3.5"

  cloud {
    organization = "Lyrasis"
    workspaces {
      name = "duracloud-production-mill"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.61.0"
    }
  }
}

provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["863649442906"]

  assume_role {
    role_arn     = "arn:aws:iam::863649442906:role/OrganizationAccountAccessRole"
    session_name = "duracloud-production-mill"
    external_id  = "duracloud-production-mill"
  }

  default_tags {
    tags = {
      Service     = "duracloud"
      Department  = "dts"
      Environment = "production"
      Project     = "mill"
      Terraform   = true
    }
  }
}
