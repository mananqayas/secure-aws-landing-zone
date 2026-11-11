provider "aws" {
  region = "ca-central-1"
}

data "aws_ssoadmin_instances" "main" {}

resource "aws_identitystore_group" "this" {
  for_each          = var.groups
  display_name      = each.value.display_name
  description       = each.value.description
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
}


resource "aws_identitystore_user" "this" {
  for_each = var.users
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  display_name = each.value.display_name
  name  {
    given_name = " "
    family_name = " "
  }
  user_name    = each.value.user_name

}

resource "aws_identitystore_group_membership" "admins" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  member_id = "ecddb5c8-7061-70a3-bedf-1eb2000ea595"
  group_id = "ac7dd5b8-5031-70b0-6bd9-f58c59c2c840"
}
