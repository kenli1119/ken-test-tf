provider "aws" {
	region = var.region
}


# -------------------------------------------
# sns

resource "aws_sns_topic" "sns-nl" {
	name = "${var.customer}-Notification"
	tags {
		name = "terraform"
		values = "nl"
	}
}

# --------------------------------------------------------------------
# alarm - ec2 statecheckfailed

resource "aws_cloudwatch_metric_alarm" "alarm" {
  count               = length(data.aws_instances.ec2id.ids)
  alarm_name          = "Warning ${var.customer} ${element(data.template_file.tag-names.*.rendered,count.index)} StatusCheckFailed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors ec2 StatusCheck"
  alarm_actions      = [aws_sns_topic.sns-nl.arn]
  treat_missing_data = "notBreaching"
  dimensions = {
    InstanceId = element(data.aws_instances.ec2id.ids, count.index)
  }
}
data "aws_instances" "ec2id" {
  filter {
    name   = "tag:Name"
    values = ["${var.ec2-tagname}*"]
  }
}
data "aws_instance" "ec2name" {
  count       = length(data.aws_instances.ec2id.ids)
  instance_id = element(data.aws_instances.ec2id.ids, count.index)
}
data "template_file" "tag-names" {
  count    = length(data.aws_instances.ec2id.ids)
  template =  data.aws_instance.ec2name[count.index].tags["Name"] 
}
#------------------------------------------------------------------------------
