##############################################################################
# The set of buckets that should just kind of be there in my AWS account
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

resource "aws_s3_bucket" "r0m4n" {
  bucket = "r0m4n.com"
  acl    = "private"
}
