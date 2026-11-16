data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "log_archive_bucket" {
  bucket = "lz-flow-logs-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_archive_bucket_encryption" {
  bucket = aws_s3_bucket.log_archive_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "log_archive_bucket_access" {
  bucket = aws_s3_bucket.log_archive_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
