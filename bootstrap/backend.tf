terraform {
  backend "s3" {
    bucket       = "mgmt-admin-terraform-state-013310058149"
    key          = "bootstrap/terraform.tfstate"
    region       = "ca-central-1"
    use_lockfile = true
  }
}
