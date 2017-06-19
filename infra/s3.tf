resource "aws_s3_bucket" "tto-serverless-video-upload" {
  bucket = "tto-serverless-video-upload"
  region = "us-east-1"
  /* lifecycle { */
  /*   prevent_destroy = true */
  /* } */
}

resource "aws_s3_bucket" "tto-serverless-video-transcoded" {
  bucket = "tto-serverless-video-transcoded"
  region = "us-east-1"
  /* lifecycle { */
  /*   prevent_destroy = true */
  /* } */
}

output "upload_bucket_arn" {
  value = "${aws_s3_bucket.tto-serverless-video-upload.arn}"
}

output "transcoded_bucket_arn" {
  value = "${aws_s3_bucket.tto-serverless-video-transcoded.arn}"
}

output "upload_bucket_id" {
  value = "${aws_s3_bucket.tto-serverless-video-upload.id}"
}

output "transcoded_bucket_id" {
  value = "${aws_s3_bucket.tto-serverless-video-transcoded.id}"
}
