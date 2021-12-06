terraform {
  required_version = "1.0.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket  = "ecs-blue-green-terraform"
    key     = "dev/terraform.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
    profile = "terraform"
  }
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = "terraform"

  default_tags {
    tags = {
      Project = var.project
    }
  }
}
