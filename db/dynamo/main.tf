##############################################################################
# Controlling AWS DynamoDB resources in this terraform file
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
  default_tags {
    tags = {
      environment = var.environment
    }
  }
}

##############################################################################
# Tables
##############################################################################

resource "aws_dynamodb_table" "dynamodb_table" {
  name           = "test_table"
  hash_key       = "id"
  range_key      = "poops"
  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "poops"
    type = "N"
  }

  lifecycle {
    ignore_changes = [
      read_capacity,
      write_capacity
    ]
  }
}
