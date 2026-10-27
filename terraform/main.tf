data "aws_caller_identity" "current" {}
resource "aws_s3_bucket" "my_bucket" {
  bucket = "manan-${data.aws_caller_identity.current.account_id}"

}
