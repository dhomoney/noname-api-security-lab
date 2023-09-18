terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket = "nn-workshop-tf-states"
    region = "us-east-2"
    key    = "terraform.tfstate"
  }
}

# Configure the AWS Provider
provider "aws" {
  default_tags {
    tags = {
      alwayson     = "True"
      cleanup         = "False"
    }
  }
}
