provider "aws" {
	region = "us-east-1"
}

#-------------------------------------------------------
# variable

variable "customer" {
}
variable "trail-bucket" {
	default = "cloudtrail-log"
}
#--------------------------------------------------------
# cloudtrail

data "aws_caller_identity" "current" {}

resource "aws_cloudtrail" "trail" {
  name                          = "${var.customer}-trail"
  s3_bucket_name                = "${aws_s3_bucket.trail-bucket.id}"
  s3_key_prefix                 = "prefix"
  include_global_service_events = true
  is_multi_region_trail = true
  enable_log_file_validation = true
  event_selector {
    read_write_type = "All"
    include_management_events = true
  }
}

#----------------------------------------------------------
resource "aws_s3_bucket" "trail-bucket" {
  bucket        = "${var.trail-bucket}"
  acl = "private"
  force_destroy = true

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${var.trail-bucket}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${var.trail-bucket}/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}
