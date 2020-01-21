# event - health issue

variable "snsname" {}


provider "aws" {}
data "aws_sns_topic" "health-sns" {
	name = var.snsname
}

resource "aws_cloudwatch_event_rule" "health" {
  name        = "healthNotification"
  description = "Notification on health detected issue."

  event_pattern = <<PATTERN
{
  "source": [
    "aws.health"
  ],
  "detail-type": [
    "AWS Health Event"
  ]
}
PATTERN

}

resource "aws_cloudwatch_event_target" "health-sns" {
  rule = "${aws_cloudwatch_event_rule.health.name}"
  arn  = "${aws_sns_topic.sns-nl.arn}"
}

