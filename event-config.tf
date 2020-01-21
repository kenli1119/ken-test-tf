
resource "aws_config_configuration_recorder" "recorder" {
  name     = "ConfigMonitor"
  role_arn = aws_iam_role.config-role.arn
  recording_group {
    all_supported = true
    include_global_resource_types = "true"
  }
}

resource "aws_iam_role" "config-role" {
  name = "configmonitor"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}
resource "aws_config_delivery_channel" "chanel" {
  name           = "config-log"
  s3_bucket_name = aws_s3_bucket.config-s3.bucket
  depends_on     = [aws_config_configuration_recorder.recorder]
}
resource "aws_s3_bucket" "config-s3" {
  bucket        = "config-log-bucket"
  force_destroy = true
}
resource "aws_iam_role_policy" "config-policy" {
  name = "config-role"
  role = aws_iam_role.config-role.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.config-s3.arn}",
        "${aws_s3_bucket.config-s3.arn}/*"
      ]
    }
  ]
}
POLICY
}
