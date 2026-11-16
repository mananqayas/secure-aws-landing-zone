locals {
  execution_role_arn = "arn:aws:iam::${var.account_id}:role/${var.bootstrapping ? "OrganizationAccountAccessRole" : var.execution_role_name}"
}

data "aws_availability_zones" "available" {
  state = "available"
}
provider "aws" {
  region = "ca-central-1"
  assume_role {
    role_arn = local.execution_role_arn

  }
}
module "baseline" {
  source                = "../../modules/account-baseline/"
  management_account_id = "013310058149"
}

module "vpc" {
  source              = "../../modules/vpc/"
  cidr_block          = "10.0.0.0/16"
  name                = "dev-vpc"
  flow_log_bucket_arn = "na"
  enable_nat_gateway  = true
  availability_zones  = data.aws_availability_zones.available.names

}
