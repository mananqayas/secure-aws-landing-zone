
# data "aws_organizations_organization" "org" {}
# 
# resource "aws_organizations_organizational_unit" "some" {
#   name = "some"
#   parent_id = data.aws_organizations_organization.org.roots[0].id
# }
# 
# 
# resource "aws_organizations_organizational_unit" "another" {
#   name      = "another"
#   parent_id = "ou-idl1-fioztzvr"
#   tags      = {}
#   tags_all  = {}
# }
