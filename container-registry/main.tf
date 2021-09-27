##############################################################################
# The container registry that I want to exist
##############################################################################

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.60.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_ecr_repository" "r0m4n" {
  name                 = "r0m4n.com"
  image_tag_mutability = "MUTABLE"
}
