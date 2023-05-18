# TERRAFORM BACKEND & PROVIDER CFG
terraform {
  required_version = "1.3.5"

  cloud {
    organization = "Lyrasis"
    workspaces {
      name = "duracloud-production-shared"
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
    session_name = "duracloud-production-shared"
    external_id  = "duracloud-production-shared"
  }

  default_tags {
    tags = {
      Service     = "duracloud"
      Department  = "dts"
      Environment = "production"
      Project     = "shared"
      Terraform   = true
    }
  }
}
