provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "tto-terra-state-up-and-running"
    key = "tto-serverless/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "tto-terra-state-up-and-running-lock-table"
  }
}
