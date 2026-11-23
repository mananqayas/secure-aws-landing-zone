data "aws_caller_identity" "current" {}

resource "aws_iam_service_linked_role" "config" {
  aws_service_name = "config.amazonaws.com"
}
