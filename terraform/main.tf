
data "aws_organizations_organization" "org" {}
resource "aws_organizations_organizational_unit" "security_ou" {

  name      = "Security"
  parent_id = data.aws_organizations_organization.org.roots[0].id

}
