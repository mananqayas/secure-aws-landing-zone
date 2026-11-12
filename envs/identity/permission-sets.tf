locals {
  permission_sets = {
    PlatformAdmins = {
      policy = "AdministratorAccess"
    }

    Developers = {
      policy = "PowerUserAccess"
    }

    ReadOnlyAuditors = {
      policy = "ReadOnlyAccess"
    }
  }
}

resource "aws_ssoadmin_permission_set" "sets" {
  for_each         = local.permission_sets
  name             = each.key
  instance_arn     = local.instance_arn
  session_duration = "PT4H"
}

resource "aws_ssoadmin_managed_policy_attachment" "policies" {
  for_each           = local.permission_sets
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.sets[each.key].arn
  managed_policy_arn = "arn:aws:iam::aws:policy/${each.value.policy}"
}
