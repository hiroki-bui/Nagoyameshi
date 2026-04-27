#------------------------------
#Terraform configuration
#------------------------------
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket  = "kadai-terraform-202614"
    key     = "network/terraform.tfstate"
    region  = "ap-northeast-1"
    profile = "terraform"
  }
}

#------------------------------
#provider
#------------------------------
provider "aws" {
  profile = "terraform"
  region  = "ap-northeast-1"
}
