resource "aws_iam_service_linked_role" "configconforms" {
  aws_service_name = "config-conforms.amazonaws.com"
}
resource "aws_iam_service_linked_role" "config_multiaccountsetup" {
  aws_service_name = "config-multiaccountsetup.amazonaws.com"
}
