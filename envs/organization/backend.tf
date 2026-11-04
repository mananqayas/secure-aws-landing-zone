terraform {
  backend "s3" {
    bucket = "mgmt-admin-terraform-state-013310058149"
    key    = "org"
    region = "ca-central-1"
    # Enable native S3 state locking
    use_lockfile = true

  }
}
