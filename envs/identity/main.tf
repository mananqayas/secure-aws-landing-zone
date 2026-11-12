provider "aws" {
  region = "ca-central-1"
}

data "aws_ssoadmin_instances" "main" {}

locals {
  instance_arn      = one(data.aws_ssoadmin_instances.main.arns)
  identity_store_id = one(data.aws_ssoadmin_instances.main.identity_store_ids)
}
