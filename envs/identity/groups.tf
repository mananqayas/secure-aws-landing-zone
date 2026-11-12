locals {
  groups = {
    ReadOnlyAuditors = "Auditors"
    PlatformAdmins   = "Platform administrators"
    Developers       = "Developers"
  }
}
resource "aws_identitystore_group" "groups" {
  for_each = local.groups

  display_name      = each.key
  description       = each.value
  identity_store_id = local.identity_store_id
}
