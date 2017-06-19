resource "aws_elastictranscoder_pipeline" "24h-elastictranscoder-video" {
  name = "24h-elastictranscoder-video"
  input_bucket = "${aws_s3_bucket.tto-serverless-video-upload.bucket}"
  role = "${aws_iam_role.default-elastictranscoder-role.arn}"

  content_config = {
    bucket = "${aws_s3_bucket.tto-serverless-video-transcoded.bucket}"
    storage_class = "Standard"
  }
  
  thumbnail_config = {
    bucket = "${aws_s3_bucket.tto-serverless-video-transcoded.bucket}"
    storage_class = "Standard"
  }
}

output "elastictranscoder_pipeline_id" {
  value = "${aws_elastictranscoder_pipeline.24h-elastictranscoder-video.id}"
}
