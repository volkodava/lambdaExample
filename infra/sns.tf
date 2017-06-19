resource "aws_sns_topic" "transcoded-video-notification" {
  name = "transcoded-video-notifications"
}

resource "aws_sns_topic_policy" "custom" {
  arn = "${aws_sns_topic.transcoded-video-notification.arn}"
  policy = <<-POLICY
  {
    "Version": "2012-10-17",
    "Id": "default",
    "Statement":[{
      "Sid": "default",
      "Effect": "Allow",
      "Principal": {"AWS":"*"},
      "Action": [
        "SNS:GetTopicAttributes",
        "SNS:SetTopicAttributes",
        "SNS:AddPermission",
        "SNS:RemovePermission",
        "SNS:DeleteTopic",
        "SNS:Publish"
      ],
      "Resource": "${aws_sns_topic.transcoded-video-notification.arn}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn":"arn:aws:s3:*:*:${aws_s3_bucket.tto-serverless-video-transcoded.id}"
        }
      }
    }]
  }
  POLICY
}

resource "aws_s3_bucket_notification" "transcode_bucket_notification" {
  bucket = "${aws_s3_bucket.tto-serverless-video-transcoded.id}"

  topic {
    topic_arn     = "${aws_sns_topic.transcoded-video-notification.arn}"
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".mp4"
  }
}

