resource "aws_lambda_function" "transcode-video-func" {
  filename = "transcode-video.zip"
  function_name = "transcode-video"
  role = "${data.terraform_remote_state.infra.lambda-s3-execution-role-arn}"
  handler = "index.handler"
  source_code_hash = "${base64sha256(file("transcode-video.zip"))}"
  runtime = "nodejs6.10"

  environment {
    variables = {
      PIPELINE_ID = "${data.terraform_remote_state.infra.elastictranscoder_pipeline_id}"
    }
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id = "AllowExecutionFromS3Bucket"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.transcode-video-func.arn}"
  principal = "s3.amazonaws.com"
  source_arn = "${data.terraform_remote_state.infra.upload_bucket_arn}"
}

resource "aws_s3_bucket_notification" "upload_notification" {
  bucket = "${data.terraform_remote_state.infra.upload_bucket_id}"
  lambda_function {
    lambda_function_arn = "${aws_lambda_function.transcode-video-func.arn}"
    events = ["s3:ObjectCreated:*"]
  }
}
