data "aws_organizations_organization" "org" {}
data "aws_organizations_organizational_units" "ous" {
  parent_id = data.aws_organizations_organization.org.roots[0].id
}
locals {
  dev_acct_id     = one([for acct in data.aws_organizations_organization.org.accounts : acct.id if acct.name == "Dev"])
  prod_acct_id    = one([for acct in data.aws_organizations_organization.org.accounts : acct.id if acct.name == "Prod"])
  root_id         = data.aws_organizations_organization.org.roots[0].id
  suspended_ou_id = one([for ou in data.aws_organizations_organizational_units.ous.children : ou.id if ou.name == "Suspended"])

}

# 1: Deny leave organization
data "aws_iam_policy_document" "deny_leave_org_policy_document" {
  statement {
    effect    = "Deny"
    actions   = ["organizations:LeaveOrganization"]
    resources = ["*"]
  }
}


resource "aws_organizations_policy" "deny_leave_org_policy" {
  name    = "DenyLeaveOrganization"
  content = data.aws_iam_policy_document.deny_leave_org_policy_document.json
}


resource "aws_organizations_policy_attachment" "org_leave" {

  for_each = {
    dev  = local.dev_acct_id
    prod = local.prod_acct_id
  }
  policy_id = aws_organizations_policy.deny_leave_org_policy.id
  target_id = each.value

}

# 2: Restrict workload resource creations only in ca-central-1 as home region
data "aws_iam_policy_document" "restrict_region_policy_doc" {
  statement {

    effect    = "Deny"
    resources = ["*"]
    not_actions = [
      "iam:*",
      "cloudfront:*",
      "sts:*",
      "route53:*",
      "support:*",
      "budgets:*",
      "organizations:*",
      "cloudtrail:LookupEvents",
      "cloudtrail:DescribeTrails",
      "cloudtrail:ListTrails",
      "cloudtrail:GetTrailStatus",
      "cloudTrail:GetEventStatus"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = ["ca-central-1"]
    }
  }
}

resource "aws_organizations_policy" "restrict_region_policy" {
  name    = "RegionAllowList"
  content = data.aws_iam_policy_document.restrict_region_policy_doc.json
}

resource "aws_organizations_policy_attachment" "restrict_region_policy_attachment" {
  for_each = {
    dev  = local.dev_acct_id
    prod = local.prod_acct_id
  }
  policy_id = aws_organizations_policy.restrict_region_policy.id
  target_id = each.value
}

# 3: Require encryption for EC2 and RDS
data "aws_iam_policy_document" "require_encryption_policy_doc" {
  statement {
    effect    = "Deny"
    actions   = ["ec2:CreateVolume"]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "ec2:Encrypted"
      values   = ["false"]
    }
  }
  statement {
    effect    = "Deny"
    actions   = ["rds:CreateDBInstance", "rds:CreateDBCluster"]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "rds:StorageEncrypted"
      values   = ["false"]
    }
  }
}

resource "aws_organizations_policy" "require_encryption_policy" {
  name    = "RequireEncryption"
  content = data.aws_iam_policy_document.require_encryption_policy_doc.json
}

resource "aws_organizations_policy_attachment" "require_encryption_policy_attachment" {
  for_each = {
    dev  = local.dev_acct_id
    prod = local.prod_acct_id
  }
  policy_id = aws_organizations_policy.require_encryption_policy.id
  target_id = each.value
}

# 4: Protect CloudTrail and Config actions
data "aws_iam_policy_document" "protect_logging_doc" {
  statement {
    effect = "Deny"
    actions = [
      "cloudtrail:StopLogging",
      "cloudTrail:DeleteTrail",
      "cloudtrail:UpdateTrail",
      "cloudtrail:DeleteEventDataStore",
      "config:StopConfigurationRecorder",
      "config:DeleteConfigurationRecorder",
      "config:DeleteDeliveryChannel"
    ]
    resources = ["*"]
  }
}

resource "aws_organizations_policy" "protect_logging_policy" {
  name    = "ProtectLogging"
  content = data.aws_iam_policy_document.protect_logging_doc.json
}

resource "aws_organizations_policy_attachment" "protect_logging_policy_attachment" {
  for_each = {
    dev  = local.dev_acct_id
    prod = local.prod_acct_id
  }

  policy_id = aws_organizations_policy.protect_logging_policy.id
  target_id = each.value
}

# 5: Deny root in members
data "aws_iam_policy_document" "deny_root_in_members_doc" {
  statement {
    effect    = "Deny"
    resources = ["*"]
    actions   = ["*"]
    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:root"]
    }
  }
}

resource "aws_organizations_policy" "deny_root_in_members_policy" {
  name    = "DenyRootInMembers"
  content = data.aws_iam_policy_document.deny_root_in_members_doc.json
}

resource "aws_organizations_policy_attachment" "deny_root_in_members_policy_attachment" {
  for_each = {
    dev  = local.dev_acct_id
    prod = local.prod_acct_id
  }
  policy_id = aws_organizations_policy.deny_root_in_members_policy.id
  target_id = each.value
}


# 6. Suspended OU deny all

data "aws_iam_policy_document" "suspended_ou_deny_all_doc" {
  statement {
    effect    = "Deny"
    resources = ["*"]
    actions   = ["*"]
  }
}

resource "aws_organizations_policy" "suspended_ou_deny_all_policy" {
  name    = "SuspendedDenyAll"
  content = data.aws_iam_policy_document.suspended_ou_deny_all_doc.json
}

resource "aws_organizations_policy_attachment" "suspended_ou_deny_all_policy_attachment" {
  policy_id = aws_organizations_policy.suspended_ou_deny_all_policy.id
  target_id = local.suspended_ou_id
}
