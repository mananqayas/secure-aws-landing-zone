data "aws_iam_policy_document" "org_conforms_pack" {
  statement {
    actions   = ["iam:CreateServiceLinkedRole"]
    effect    = "Allow"
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/config-conforms.amazonaws.com/AWSServiceRoleForConfigConforms"]
    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["config-conforms.amazonaws.com"]
    }
  }
  statement {
    actions   = ["iam:CreateServiceLinkedRole"]
    effect    = "Allow"
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/config-multiaccountsetup.amazonaws.com/AWSServiceRoleForConfigMultiAccountSetup"]
    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["config-multiaccountsetup.amazonaws.com"]
    }
  }
  statement {
    effect    = "Allow"
    actions   = ["iam:GetRole", "iam:GetRolePolicy", "iam:ListRolePolicies", "iam:ListAttachedRolePolicies"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/config-conforms.amazonaws.com/AWSServiceRoleForConfigConforms", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/config-multiaccountsetup.amazonaws.com/AWSServiceRoleForConfigMultiAccountSetup"]
  }
}

resource "aws_iam_policy" "org_conforms_slr" {
  name   = "allow-apply-role-create-mgmt-slr-for-org-conforms"
  policy = data.aws_iam_policy_document.org_conforms_pack.json
}

resource "aws_iam_role_policy_attachment" "attach_org_conforms_policy" {
  role       = aws_iam_role.apply_role.name
  policy_arn = aws_iam_policy.org_conforms_slr.arn
}
