# 1: Deny leave organization
data "aws_iam_policy_document" "deny_leave_org_policy_document" {
  statement {
    effect    = "Deny"
    actions   = ["organizations:LeaveOrganization"]
    resources = ["*"]
  }
}


resource "aws_organizations_policy" "deny_leave_org_policy" {
  name    = "deny-leave-org"
  content = data.aws_iam_policy_document.deny_leave_org_policy_document.json
}

data "aws_organizations_organization" "org" {}

locals {
  dev_acct_id  = one([for acct in data.aws_organizations_organization.org.accounts : acct.id if acct.name == "Dev"])
  prod_acct_id = one([for acct in data.aws_organizations_organization.org.accounts : acct.id if acct.name == "Prod"])
  root_id      = data.aws_organizations_organization.org.roots[0].id

}

resource "aws_organizations_policy_attachment" "org_leave" {

  policy_id = aws_organizations_policy.deny_leave_org_policy.id
  target_id = local.dev_acct_id

}
