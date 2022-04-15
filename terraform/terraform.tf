terraform {

    required_version = "~> 1.1.7"
    required_providers {
          aws = {
                source  = "hashicorp/aws"
                version = "~> 4.0"
          }
    }


  backend "s3" {
    bucket  = "f-saito-example-terraform-state"
    key     = "dev/terraform.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
  }
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = "default"

  default_tags {
    tags = {
      Project = var.project
    }
  }
}
