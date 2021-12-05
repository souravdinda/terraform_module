data "aws_caller_identity" "current" {}
locals {
    account_id = data.aws_caller_identity.current.account_id
}
data "aws_region" "current" { }
locals {
    region = data.aws_region.current.name
}


resource "aws_sns_topic" "user_updates" {
  display_name = "${var.Namespace}-EC2CloudWatchTopic-${local.region}"
  name = "${var.Namespace}-EC2CloudWatchTopic-${local.region}"


  tags ={
    "${var.TagOrgKey}"="${var.TagOrgValue}"
    "${var.TagTeamKey}"="${var.TagTeamValue}",
    "${var.TagDepartmentKey}"="${var.TagDepartmentValue}",
    "${var.TagProjectKey}"="${var.TagProjectValue}",
    "${var.TagStageKey}"="${var.TagStageValue}",
    "${var.TagCostCenterKey}"="${var.TagCostCenterValue}",
    "${var.TagDataClassificationKey}"="${var.TagDataClassificationValue}"

  }

}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "email"
  endpoint  = var.TopicEmail
}

resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.user_updates.arn

  policy = jsonencode({
    "Version": "2012-10-17",
    "Id": "Default_Policy",
    "Statement": [
      {
        "Sid": "Default Statement",
        "Effect": "Allow",
        "Principal": {
          "AWS": "*"
        },
        "Action": [
          "sns:Publish",
          "sns:RemovePermission",
          "sns:SetTopicAttributes",
          "sns:DeleteTopic",
          "sns:ListSubscriptionsByTopic",
          "sns:GetTopicAttributes",
          "sns:Receive",
          "sns:AddPermission",
          "sns:Subscribe"
        ],
        "Resource": "arn:aws:sns:${local.region}:${local.account_id}:${var.Namespace}-EC2CloudWatchTopic-${local.region}",
        "Condition": {
          "StringEquals": {
            "AWS:SourceAccount": "${local.account_id}"
          }
        }
      },
      {
        "Sid": "TrustCWEnSSMToPublishEventsToMyTopic",
        "Effect": "Allow",
        "Principal": {
          "Service": [
            "cloudwatch.amazonaws.com",
            "ssm.amazonaws.com",
            "events.amazonaws.com"
          ]
        },
        "Action": "sns:Publish",
        "Resource": "arn:aws:sns:${local.region}:${local.account_id}:${var.Namespace}-EC2CloudWatchTopic-${local.region}"
      }
    ]
  })
}
