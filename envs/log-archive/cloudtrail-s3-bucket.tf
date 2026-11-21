resource "aws_s3_bucket" "cloud_trail_bucket" {
  bucket = "cloudtrail-logs-408873346185"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.cloud_trail_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.cloud_trail_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid     = "AWSCloudTrailAclCheck"
    actions = ["s3:GetBucketAcl"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:ca-central-1:013310058149:trail/org-trail"]
    }
    resources = [aws_s3_bucket.cloud_trail_bucket.arn]
  }

  statement {
    sid       = "AWSCloudTrailWrite"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloud_trail_bucket.arn}/AWSLogs/013310058149/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:ca-central-1:013310058149:trail/org-trail"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
  statement {
    sid       = "AWSCloudTrailWriteOrg"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloud_trail_bucket.arn}/AWSLogs/o-4nhn73sdcv/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:ca-central-1:013310058149:trail/org-trail"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }


}
