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

# One repository points to one image. ECR is a flat hierarchy.
resource "aws_ecr_repository" "fake_data" {
  name                 = "r0m4n.com/fake-data-api"
  image_tag_mutability = "MUTABLE"
}
