# 
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
#   parent_id = aws_organizations_organizational_unit.some.id
#   depends_on = [aws_organizations_organizational_unit.some]
#   tags      = {}
#   tags_all  = {}
# }
