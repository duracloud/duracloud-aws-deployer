# TERRAFORM BACKEND & PROVIDER CFG
terraform {
  required_version = "1.3.5"

  cloud {
    organization = "Lyrasis"
    workspaces {
      name = "duracloud-development-management-console"
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
  allowed_account_ids = ["380144836391"]

  assume_role {
    role_arn     = "arn:aws:iam::380144836391:role/OrganizationAccountAccessRole"
    session_name = "duracloud-development-management-console"
    external_id  = "duracloud-development-management-console"
  }

  default_tags {
    tags = {
      Service     = "duracloud"
      Department  = "dts"
      Environment = "development"
      Project     = "management-console"
      Terraform   = true
    }
  }
}
