locals {
  account_id = module.baseline.account_id
}
data "aws_iam_policy_document" "config_aggregator_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

  }
}
resource "aws_iam_role" "terraform_config" {
  name                 = "terraform-config-aggregator"
  assume_role_policy   = data.aws_iam_policy_document.config_aggregator_assume_role_policy.json
  permissions_boundary = "arn:aws:iam::${local.account_id}:policy/terraform-boundary"
}

resource "aws_iam_role_policy_attachment" "terraform_config" {
  role       = aws_iam_role.terraform_config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

resource "aws_config_configuration_aggregator" "config_aggregator" {
  name       = "org-config-aggregator"
  depends_on = [aws_iam_role_policy_attachment.terraform_config]
  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.terraform_config.arn
  }

}
