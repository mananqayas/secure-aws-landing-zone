locals {
  users = {
    mananqayas = {
      given_name  = "Manan"
      family_name = "Qayas"
    }
    dev-probe = {
      given_name  = "Manan"
      family_name = "Qayas"
    }
    auditor-probe = {
      given_name  = "Manan"
      family_name = "Qayas"
    }
  }
}
resource "aws_identitystore_user" "users" {
  for_each = local.users

  identity_store_id = local.identity_store_id
  display_name      = "${each.value.given_name} ${each.value.family_name}"
  name {
    given_name  = each.value.given_name
    family_name = each.value.family_name
  }
  user_name = each.key
}
