provider "aws" {
  region  = var.aws_deploy_region
  profile = var.aws_profile
  assume_role {
    role_arn     = "arn:aws:iam::${var.aws_deploy_account}:role/aws-reserved/sso.amazonaws.com/${var.aws_deploy_region}/${var.aws_deploy_iam_role_name}"
    session_name = "Terraform"
  }
}

terraform {
  required_version = ">= 0.14.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
  backend "s3" {
    region  = "eu-west-2"
    key     = "tfstate"
    bucket  = "madetech-sandbox-terraform-state"
    encrypt = true
  }
}