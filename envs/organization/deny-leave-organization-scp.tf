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
