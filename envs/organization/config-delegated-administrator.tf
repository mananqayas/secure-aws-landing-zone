resource "aws_organizations_delegated_administrator" "config_admin" {
  account_id        = "996560370921"
  service_principal = "config.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "config_multiaccountsetup_admin" {
  account_id        = "996560370921"
  service_principal = "config-multiaccountsetup.amazonaws.com"
}
