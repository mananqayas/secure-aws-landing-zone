data "aws_caller_identity" "current" {}

#Create terraform boundary policy


#1. Data source for policy json
#2. Create AWS IAM Policy

data "aws_iam_policy_document" "boundary_policy_document" {

  statement {
    sid         = "AllowAllButIAM"
    resources   = ["*"]
    not_actions = ["iam:*"]
  }
  statement {
    sid = "MemberIAMManage"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:ListPolicyVersions",
      "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/terraform-*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/terraform-*"
    ]
  }
  statement {
    sid       = "MemberCreateRole"
    actions   = ["iam:CreateRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/terraform-*"]
    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/terraform-boundary"]
    }
  }
  statement {
    sid       = "AllowGetRoleOnOAA"
    actions   = ["iam:GetRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/OrganizationAccountAccessRole"]
  }
}

data "aws_iam_policy_document" "plan_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.management_account_id}:role/plan-role"]
    }
  }
}

resource "aws_iam_policy" "boundary_policy" {
  name   = "terraform-boundary"
  policy = data.aws_iam_policy_document.boundary_policy_document.json
}

resource "aws_iam_role" "terraform_plan" {
  name                 = "terraform-plan"
  assume_role_policy   = data.aws_iam_policy_document.plan_trust.json
  permissions_boundary = aws_iam_policy.boundary_policy.arn
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.terraform_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
