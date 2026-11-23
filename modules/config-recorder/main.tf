data "aws_caller_identity" "current" {}

resource "aws_iam_service_linked_role" "config" {
  aws_service_name = "config.amazonaws.com"
}

# resource "aws_config_configuration_recorder" "config_recorder" {
#   name     = "config-recorder"
#   role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"
#   recording_group {
#     all_supported = true
#   }
#   depends_on = [aws_iam_service_linked_role.config]
# }
# 
# resource "aws_config_delivery_channel" "config_recorder_delivery" {
#   name           = "config-recorder-channel"
#   s3_bucket_name = "arn:aws:s3:::config-logs-408873346185"
# }
# 
# resource "aws_config_configuration_recorder_status" "config_recorder_status" {
#   name       = aws_config_configuration_recorder.config_recorder.name
#   is_enabled = true
#   depends_on = [aws_config_delivery_channel.config_recorder_delivery]
# 
# }
