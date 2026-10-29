data "aws_caller_identity" "current" {}
resource "aws_s3_bucket" "my_bucket" {
  bucket = "manan-${data.aws_caller_identity.current.account_id}"

}

data "aws_organizations_organization" "org" {}
resource "aws_organizations_organizational_unit" "example" {

  name      = "example"
  parent_id = data.aws_organizations_organization.org.roots[0].id

}
