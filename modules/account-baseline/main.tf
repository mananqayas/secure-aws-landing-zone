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
      "iam:ListInstanceProfilesForRole",
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
    actions   = [
      "iam:GetRole",
      "iam:ListRolePolicies",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies"
    ]
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

# 2 policy for terraform-deploy role
data "aws_iam_policy_document" "deploy_identity_policy_doc" {
  statement {
    sid         = "AllowAllButIAM"
    resources   = ["*"]
    not_actions = ["iam:*"]
  }
  statement {
    sid    = "MemberIAMManage"
    effect = "Allow"
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
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/terraform-*", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/terraform-*"
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
    sid    = "MemberProtect"
    effect = "Deny"
    not_actions = [
      "iam:GetRole",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:ListPolicyVersions"
    ]
    resources = [
      aws_iam_policy.boundary_policy.arn,
      aws_iam_role.terraform_plan.arn,
      aws_iam_role.terraform_deploy_role.arn,
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/OrganizationAccountAccessRole"
    ]
  }

  statement {
    sid       = "AllowGetRoleOnOAA"
    actions   = [
      "iam:GetRole",
      "iam:ListRolePolicies"
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/OrganizationAccountAccessRole"]
  }
}

resource "aws_iam_policy" "deploy_role_policy" {
  name   = "terraform-deploy-role-policy"
  policy = data.aws_iam_policy_document.deploy_identity_policy_doc.json
}

data "aws_iam_policy_document" "deploy_role_assume_policy_doc" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.management_account_id}:role/apply-role"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "terraform_deploy_role" {
  name               = "terraform-deploy"
  assume_role_policy = data.aws_iam_policy_document.deploy_role_assume_policy_doc.json
  permissions_boundary = aws_iam_policy.boundary_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_deploy_role_policy" {
  role       = aws_iam_role.terraform_deploy_role.name
  policy_arn = aws_iam_policy.deploy_role_policy.arn
}

data "aws_iam_policy_document" "oaa_trust" {

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.management_account_id}:root"]
    }

  }

}
resource "aws_iam_role" "oaa" {
  name                 = "OrganizationAccountAccessRole"
  assume_role_policy   = data.aws_iam_policy_document.oaa_trust.json
  permissions_boundary = aws_iam_policy.boundary_policy.arn

  lifecycle {
    ignore_changes = [
      assume_role_policy, description, max_session_duration, tags
    ]
  }

}

import {
  to = aws_iam_role.oaa
  id = "OrganizationAccountAccessRole"
}

resource "aws_s3_account_public_access_block" "this" {

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_ebs_encryption_by_default" "this" {
  enabled = true
}
