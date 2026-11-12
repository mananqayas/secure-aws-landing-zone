locals {
  assignments = {
    PlatformAdmins = {
      accountIds = ["013310058149", "408873346185", "996560370921", "102199089014", "503440159390"]
    }
    Developers = {
      accountIds = ["102199089014"]
    }
    ReadOnlyAuditors = {
      accountIds = ["013310058149", "408873346185", "996560370921", "102199089014", "503440159390"]
    }
  }

  flatten_assignments = flatten([
    for group_key, account_data in local.assignments : [
      for account_id in account_data.accountIds : {
        pair_key   = "${group_key}-${account_id}"
        group_key  = group_key
        account_id = account_id
      }
    ]
  ])

  assignments_map = {
    for item in local.flatten_assignments : item.pair_key => item
  }
}
resource "aws_ssoadmin_account_assignment" "assignments" {
  for_each           = local.assignments_map
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.sets[each.value.group_key].arn

  principal_id   = aws_identitystore_group.groups[each.value.group_key].group_id
  principal_type = "GROUP"

  target_id = each.value.account_id
  target_type = "AWS_ACCOUNT"

}
