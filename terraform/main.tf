

data "aws_organizations_organization" "org" {}
# import {
# to = aws_organizations_organizational_unit.imported_ou
# id = "ou-idl1-fioztzvr"

# }

# resource "aws_organizations_organizational_unit" "imported_ou" {}
resource "aws_organizations_organizational_unit" "security_ou" {

  name      = "Security"
  parent_id = data.aws_organizations_organization.org.roots[0].id

}
# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform from "ou-idl1-fioztzvr"
#resource "aws_organizations_organizational_unit" "imported_ou" {
# name      = "some"
# parent_id = "r-idl1"
# tags      = {}
# tags_all  = {}
#}
