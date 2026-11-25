locals {
  account_id = module.baseline.account_id
}
data "aws_iam_policy_document" "config_aggregator_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

  }
}
resource "aws_iam_role" "terraform_config" {
  name                 = "terraform-config-aggregator"
  assume_role_policy   = data.aws_iam_policy_document.config_aggregator_assume_role_policy.json
  permissions_boundary = "arn:aws:iam::${local.account_id}:policy/terraform-boundary"
}

resource "aws_iam_role_policy_attachment" "terraform_config" {
  role       = aws_iam_role.terraform_config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

resource "aws_config_configuration_aggregator" "config_aggregator" {
  name       = "org-config-aggregator"
  depends_on = [aws_iam_role_policy_attachment.terraform_config]
  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.terraform_config.arn
  }

}

resource "aws_s3_bucket" "conformance_pack_bucket" {
  bucket = "awsconfigconforms-996560370921"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.conformance_pack_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.conformance_pack_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    effect    = "Allow"
    sid       = "AWSConfigConformsBucketPermissionsCheck"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.conformance_pack_bucket.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgId"
      values   = ["o-4nhn73sdcv"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:role/aws-service-role/config-conforms.amazonaws.com/AWSServiceRoleForConfigConforms"]
    }
  }

  statement {
    sid       = "AWSConfirConformsBucketReadAndWrite"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = [aws_s3_bucket.conformance_pack_bucket.arn, "${aws_s3_bucket.conformance_pack_bucket.arn}/*"]
    effect    = "Allow"
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgId"
      values   = ["o-4nhn73sdcv"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:role/aws-service-role/config-conforms.amazonaws.com/AWSServiceRoleForConfigConforms"]
    }
  }
  statement {
    sid       = "DenyInsecureTransport"
    actions   = ["s3:*"]
    effect    = "Deny"
    resources = [aws_s3_bucket.conformance_pack_bucket.arn, "${aws_s3_bucket.conformance_pack_bucket.arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.conformance_pack_bucket.id
  policy = data.aws_iam_policy_document.bucket_policy.json

}
