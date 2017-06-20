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
    key = "tto-serverless/transcode-video/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "tto-terra-state-up-and-running-lock-table"
  }
}

resource "aws_lambda_function" "func" {
  filename = "func.zip"
  function_name = "transcode-video"
  source_code_hash = "${base64sha256(file("func.zip"))}"
  runtime = "nodejs6.10"
  handler = "index.handler"
  role = "${data.terraform_remote_state.infra.lambda-s3-execution-role-arn}"

  environment  {
    variables = {
      PIPELINE_ID = "${data.terraform_remote_state.infra.elastictranscoder_pipeline_id}"
    }
  }
}

resource "aws_s3_bucket_notification" "upload_notification" {
  bucket = "${data.terraform_remote_state.infra.upload_bucket_id}"
  lambda_function {
    lambda_function_arn = "${aws_lambda_function.func.arn}"
    events = ["s3:ObjectCreated:*"]
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id = "AllowExecutionFromS3Bucket"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.func.arn}"
  principal = "s3.amazonaws.com"
  source_arn = "${data.terraform_remote_state.infra.upload_bucket_arn}"
}
