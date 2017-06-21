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
    key = "tto-serverless/set-permission/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "tto-terra-state-up-and-running-lock-table"
  }
}

resource "aws_lambda_function" "func" {
  filename = "func.zip"
  function_name = "set-permission"
  source_code_hash = "${base64sha256(file("func.zip"))}"
  runtime = "nodejs6.10"
  handler = "index.handler"
  role = "${data.terraform_remote_state.infra.lambda-s3-execution-role-arn}"
}

resource "aws_lambda_permission" "with_sns" {
  statement_id = "AllowExecutionFromSNS"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.func.arn}"
  principal = "sns.amazonaws.com"
  source_arn = "${data.terraform_remote_state.infra.transcoded-video-notification-arn}"
}

resource "aws_sns_topic_subscription" "update_acl_subscription" {
  topic_arn = "${data.terraform_remote_state.infra.transcoded-video-notification-arn}"
  protocol = "lambda"
  endpoint = "${aws_lambda_function.func.arn}"
}
