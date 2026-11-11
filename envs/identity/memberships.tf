locals {
  memberships = {
    mananqayas = {
      user  = "mananqayas"
      group = "PlatformAdmins"
    }
    dev-probe = {
      user  = "dev-probe"
      group = "Developers"
    }
    auditor-probe = {
      user  = "auditor-probe"
      group = "ReadOnlyAuditors"
    }
  }
}

resource "aws_identitystore_group_membership" "memberships" {
	for_each = local.memberships
	identity_store_id = local.identity_store_id
	group_id = aws_identitystore_group.groups[each.value.group].group_id
	member_id = aws_identitystore_user.users[each.value.user].user_id
}
