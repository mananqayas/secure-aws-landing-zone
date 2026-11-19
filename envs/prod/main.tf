locals {
  execution_role_arn = "arn:aws:iam::${var.account_id}:role/${var.bootstrapping ? "OrganizationAccountAccessRole" : var.execution_role_name}"
}
data "aws_availability_zones" "available" {}
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
  cidr_block          = "10.1.0.0/16"
  name                = "prod-vpc"
  flow_log_bucket_arn = "arn:aws:s3:::lz-flow-logs-408873346185"
  enable_nat_gateway  = false
  availability_zones  = data.aws_availability_zones.available.names
  public_nacl_rules = {
    rule_1 = {
      rule_number = 50
      protocol    = "tcp"
      from_port   = 3389
      to_port     = 3389
      cidr_block  = "0.0.0.0/0"
      rule_action = "deny"
      egress      = false
    }

#     rule_2 = {
#       rule_number = 90
#       protocol    = "tcp"
#       from_port   = 22
#       to_port     = 22
#       cidr_block  = ""
#       rule_action = "allow"
#       egress      = false
#     }

    rule_3 = {
      rule_number = 100
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_block  = "0.0.0.0/0"
      rule_action = "allow"
      egress      = false
    }

    rule_4 = {
      rule_number = 110
      protocol    = "tcp"
      from_port   = 1024
      to_port     = 65535
      cidr_block  = "0.0.0.0/0"
      rule_action = "allow"
      egress      = false
    }

    rule_5 = {
      rule_number = 100
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      cidr_block  = "10.1.0.0/16"
      rule_action = "allow"
      egress      = true
    }

    rule_6 = {
      rule_number = 110
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_block  = "0.0.0.0/0"
      rule_action = "allow"
      egress      = true
    }

    rule_7 = {
      rule_number = 120
      protocol    = "tcp"
      from_port   = 1024
      to_port     = 65535
      cidr_block  = "0.0.0.0/0"
      rule_action = "allow"
      egress      = true
    }
  }
  private_nacl_rules = {
    rule_1 = {
      rule_number = 100
      egress      = false
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "10.1.0.0/16"
      rule_action = "allow"
    },

    rule_2 = {
      rule_number = 110
      egress      = false
      from_port   = 1024
      to_port     = 65535
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      rule_action = "allow"
    },

    rule_3 = {
      rule_number = 100
      egress      = true
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "10.1.0.0/16"
      rule_action = "allow"
    },

    rule_4 = {
      rule_number = 110
      egress      = true
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      rule_action = "allow"
    },

    rule_5 = {
      rule_number = 120
      egress      = true
      from_port   = 1024
      to_port     = 65535
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      rule_action = "allow"
    },


  }

}
