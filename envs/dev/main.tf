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
  flow_log_bucket_arn = "arn:aws:s3:::lz-flow-logs-408873346185"
  enable_nat_gateway  = false
  availability_zones  = data.aws_availability_zones.available.names
  nacl_rules = {
    "rule_1" : {
      "rule_number" : 50,
      protocol : "tcp",
      "from_port" : 3389,
      "to_port" : 3389,
      cidr_block : "0.0.0.0/0",
      rule_action : "deny",
      egress : false
    }
  }

}
