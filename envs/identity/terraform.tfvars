groups = {
  admins = {
    display_name = "PlatformAdmins"
    description  = "Platform admins group"
  }
  developers = {
    display_name = "Developers"
    description  = "Developers group"
  }
  auditors = {
    display_name = "ReadOnlyAuditors"
    description  = "Auditors group"
  }
}

users = {
  mananqayas = {
    display_name = "Manan Qayas"
    user_name    = "mananqayas"
    groups = ["admins"]
  }
  dev = {
    display_name = "Developer"
    user_name    = "dev-probe"
    groups = ["developers"]
  }
  auditor = {
    display_name = "Auditor"
    user_name    = "auditor-probe"
    groups = ["auditors"]
  }
}
