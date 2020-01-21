provider "aws" {
  region = var.region
}

#-------------------------------------------------------------------------------

data "aws_caller_identity" "current" {
}

#----------------------------------------------------------------------
# variable

variable "customer" {
}

variable "system" {
}

variable "channel" {
}

variable "region" {
}

variable "lambda-name" {
  default = "Nextlink-Notification"
}

#----------------------------------------------------------------------
# cloudwatch event on ec2state

resource "aws_cloudwatch_event_rule" "rule" {
  name        = "EC2StateChange"
  description = "Capture each AWS EC2 State Change"

  event_pattern = <<PATTERN
        {
          "source": [
                "aws.ec2"
                 ],
          "detail-type": [
            "EC2 Instance State-change Notification"
          ],
          "detail": {
            "state": [
              "pending",
              "stopped",
              "shutting-down"
            ]
          }
        }
        
PATTERN

}

resource "aws_cloudwatch_event_target" "target" {
  rule = aws_cloudwatch_event_rule.rule.name
  arn  = aws_lambda_function.lambda.arn
}

#---------------------------------------------------------------------------------
# lambda 

resource "aws_lambda_function" "lambda" {
  filename      = "function.zip"
  function_name = var.lambda-name
  role          = aws_iam_role.role.arn
  handler       = "main"
  runtime       = "go1.x"
  environment {
    variables = {
      CHANNEL     = var.channel
      USERNAME    = "${var.customer}-${var.system}"
      WEBHOOK_URL = "https://mattermost.nextlink.technology/hooks/ux714mih4jdb9bsxsofyoz5hmy"
    }
  }
}

resource "aws_lambda_permission" "permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rule.arn
}

#---------------------------------------------------------------------------------------
# role

resource "aws_iam_role" "role" {
  name = "Nextlink-lambdaNotification"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF


  tags = {
    tf = "monitor"
  }
}

resource "aws_iam_role_policy" "lambda-policy" {
  name = "Nextlink-lambdaNotification"
  role = aws_iam_role.role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"
    },
    {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.lambda-name}:*"
            ]
        }
    ]
}
EOF
}

