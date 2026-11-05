#Create terraform boundary policy

#1. Data source for policy json
#2. Create AWS IAM Policy

data "aws_iam_policy_document" "boundary_policy_document" {
  statement {
    sid         = "AllowAllButIAM"
    actions     = ["*"]
    resources   = ["*"]
    not_actions = ["iam:*"]
  }
}

resource "aws_iam_policy" "boundary_policy" {
  name   = "terraform-boundary"
  policy = data.aws_iam_policy_document.boundary_policy_document.json
}
