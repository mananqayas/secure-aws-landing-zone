terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
  required_version = ">= 1.2"
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "mgmt-admin-terraform-state-013310058149"
    key    = "tf-state/terraform.tfstate"
    region = "ca-central-1"
  }
}

terraform {
  backend "s3" {
    bucket = "mgmt-admin-terraform-state-013310058149"
    key    = "org/terraform.tfstate"
    region = "ca-central-1"

  }

}
