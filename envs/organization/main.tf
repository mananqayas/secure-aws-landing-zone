provider "aws" {
  region = "ca-central-1"
}

module "aws_organization" {

  source = "../../modules/organization"

  # Define OUs

  organizational_units = {
    security  = { name : "Security" }
    workloads = { name : "Workloads" }
    suspended = { name : "Suspended" }
  }

  accounts = {
    log_archive = {
      name              = "Log Archive"
      email             = "transivone.official+aws-lz+log-archive@gmail.com"
      ou_key            = "security"
      close_on_deletion = true
    }
    audit = {
      name              = "Audit"
      email             = "transivone.official+aws-lz+audit@gmail.com"
      ou_key            = "security"
      close_on_deletion = true
    }
    dev = {
      name              = "Dev"
      email             = "transivone.official+aws-lz+dev@gmail.com"
      ou_key            = "workloads"
      close_on_deletion = true
    }
    prod = {
      name              = "Prod"
      email             = "transivone.official+aws-lz+prod@gmail.com"
      ou_key            = "workloads"
      close_on_deletion = false
    }
  }
}

# Instantiate config module
module "config" {
  source = "../../modules/config-recorder/"
}
