provider "aws" {
  region = "ca-central-1"
}

data "aws_organizations_organization" "org" {}

resource "aws_organizations_organizational_unit" "this" {
  for_each  = var.organizational_units
  name      = each.value.name
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_account" "this" {
  for_each  = var.accounts
  name      = each.value.name
  email     = each.value.email
  parent_id = lookup(aws_organizations_organizational_unit.this, each.value.ou_key, data.aws_organizations_organization.org.roots[0]).id

  close_on_deletion = each.value.close_on_deletion

  lifecycle {
    ignore_changes = [role_name]
  }

}
