terraform {
  backend "s3" {
    bucket       = "mgmt-admin-terraform-state-013310058149"
    key          = "identity/terraform.tfstate"
    use_lockfile = true
  }
}
