data "aws_iam_policy_document" "config_policy_doc" {
  statement {
    sid = "ConfigRecorderCreate"
    actions = [
      "config:PutConfigurationRecorder",
      "config:DescribeConfigurationRecorders",
      "config:DescribeConfigurationRecorderStatus",
      "config:StartConfigurationRecorder",
      "config:StopConfigurationRecorder",
      "config:DeleteConfigurationRecorder",
      "config:PutDeliveryChannel",
      "config:DescribeDeliveryChannels",
      "config:DescribeDeliveryChannelStatus",
      "config:DeleteDeliveryChannel"
    ]

    resources = ["*"]
    effect    = "Allow"
  }
  statement {
    sid       = "ConfigSLRCreate"
    actions   = ["iam:CreateServiceLinkedRole"]
    effect    = "Allow"
    resources = ["arn:aws:iam::013310058149:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"]
    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["config.amazonaws.com"]
    }
  }

  statement {
    sid       = "GetConfigServiceRole"
    actions   = ["iam:GetRole", "iam:ListRolePolicies", "iam:ListAttachedRolePolicies", "iam:GetRolePolicy"]
    resources = ["arn:aws:iam::013310058149:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"]
    effect    = "Allow"

  }

  statement {
    sid       = "ConfigSLRPassRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::013310058149:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["config.amazonaws.com"]
    }
  }

}

resource "aws_iam_policy" "apply_role_config_policy" {
  name   = "config-permissions"
  policy = data.aws_iam_policy_document.config_policy_doc.json
}
resource "aws_iam_role_policy_attachment" "policy_attachment_for_config" {

  role       = aws_iam_role.apply_role.name
  policy_arn = aws_iam_policy.apply_role_config_policy.arn
}
