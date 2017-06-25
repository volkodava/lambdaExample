provider "aws" {
  region = "us-east-1"
}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config {
    bucket = "tto-terra-state-up-and-running"
    key = "tto-serverless/terraform.tfstate"
    region = "us-east-1"
  }
}

terraform {
  backend "s3" {
    bucket = "tto-terra-state-up-and-running"
    key = "tto-serverless/custom-authorizer/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "tto-terra-state-up-and-running-lock-table"
  }
}

resource "aws_lambda_function" "func" {
  filename = "func.zip"
  function_name = "custom-authorizer"
  source_code_hash = "${base64sha256(file("func.zip"))}"
  runtime = "nodejs6.10"
  handler = "index.handler"
  role = "${data.terraform_remote_state.infra.api-gateway-lambda-exec-role-arn}"
  environment  {
    variables = {
      DOMAIN = "c63.auth0.com"
      AUTH0_SECRET = "f7Cl3MRjnVMg6hDGA5W-ruxpo9uscZqGQdMFPgfckRCwqzbyCDg3OkqKAWMMgzLA"
    }
  }
}

resource "aws_api_gateway_authorizer" "custom_authorizer" {
  name = "demo"
  rest_api_id = "${data.terraform_remote_state.infra.demo-serverless-rest-api-id}"
  authorizer_uri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.func.arn}/invocations"
  authorizer_credentials = "${aws_iam_role.invocation_role.arn}"
}

resource "aws_iam_role" "invocation_role" {
  name = "api_gateway_auth_invocation"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "apigateway.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "invocation_policy" {
  name = "default"
  role = "${aws_iam_role.invocation_role.id}"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "lambda:InvokeFunction",
        "Effect": "Allow",
        "Resource": "${aws_lambda_function.func.arn}"
      }
    ]
  }
  EOF
}
