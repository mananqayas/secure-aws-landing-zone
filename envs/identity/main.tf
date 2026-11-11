provider "aws" {
  region = "ca-central-1"
}

data "aws_ssoadmin_instances" "main" {}

output "sso_instance_details" {
  value = data.aws_ssoadmin_instances.main
}

resource "aws_ssoadmin_permission_set" "test" {
  instance_arn = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  name         = "AdministratorAccess"
}

import {

  to = aws_ssoadmin_permission_set.test
  id = "arn:aws:sso:::permissionSet/ssoins-8824ef7bf9ab4056/ps-88242fe32c0f8fee,arn:aws:sso:::instance/ssoins-8824ef7bf9ab4056"
}
