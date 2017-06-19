resource "aws_iam_role" "lambda-s3-execution-role" {
  name = "lambda-s3-execution-role"
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "lambda-s3-execution-role-elastic-transcoder-job-submitter-attachment" {
  role = "${aws_iam_role.lambda-s3-execution-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticTranscoderJobsSubmitter"
}

resource "aws_iam_role_policy_attachment" "lambda-s3-execution-role-lambda-execute-policy-attachment" {
  role = "${aws_iam_role.lambda-s3-execution-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

data "aws_iam_policy_document" "default-elastictranscoder-policy-document" {
  statement  {
    sid = "1"
    effect = "Allow"
    actions = [
      "s3:Put*",
      "s3:ListBucket",
      "s3:*MultipartUpload*",
      "s3:Get*"
    ]
    resources = ["*"]
  }
  statement  {
    sid = "2"
    effect = "Allow"
    actions= [
      "sns:Publish"
    ]
    resources = ["*"]
  }
  statement  {
    sid = "3"
    effect = "Deny"
    actions = [
      "s3:*Delete*",
      "s3:*Policy*",
      "sns:*Remove*",
      "sns:*Delete*",
      "sns:*Permission*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "default-elastictranscoder-role" {
  name = "default-elastictranscoder-role"
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "elastictranscoder.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_policy" "default-elastictranscoder-policy" {
  name   = "default-elastictranscoder-policy"
  policy = "${data.aws_iam_policy_document.default-elastictranscoder-policy-document.json}"
}

resource "aws_iam_role_policy_attachment" "default-elastic-transcoder-role-policy-attachment" {
  role = "${aws_iam_role.default-elastictranscoder-role.name}"
  policy_arn = "${aws_iam_policy.default-elastictranscoder-policy.arn}"
}

output "lambda-s3-execution-role-arn" {
   value = "${aws_iam_role.lambda-s3-execution-role.arn}" 
}