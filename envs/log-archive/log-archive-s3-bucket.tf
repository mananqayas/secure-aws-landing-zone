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

data "aws_iam_policy_document" "allow_access_for_flow_logs" {
  statement {
    sid = "AWSLogDeliveryAclCheck"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.log_archive_bucket.arn]
  }
  statement {
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [102199089014, 503440159390]
    }

    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.log_archive_bucket.arn}/AWSLogs/102199089014/*", "${aws_s3_bucket.log_archive_bucket.arn}/AWSLogs/503440159390/*"]
  }
  statement {
    actions = ["s3:*"]
    effect  = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    resources = [aws_s3_bucket.log_archive_bucket.arn, "${aws_s3_bucket.log_archive_bucket.arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "attach_policy_for_delivery_logs_from_dev_and_prod" {
  bucket = aws_s3_bucket.log_archive_bucket.id
  policy = data.aws_iam_policy_document.allow_access_for_flow_logs.json
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_config" {
  bucket = aws_s3_bucket.log_archive_bucket.id

  rule {
    id     = "lifecycle"
    status = "Enabled"
    filter {}
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    expiration {
      days = 365
    }
  }
}
