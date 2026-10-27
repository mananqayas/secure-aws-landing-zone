# 1. Fetch current AWS Account ID dynamically
data "aws_caller_identity" "current" {}

provider "aws" {
  region  = "ca-central-1"
  profile = "mgmt-admin"
}

# 2. Create the KMS Key with the 2 required policy statements
resource "aws_kms_key" "terraform_state_key" {

  description             = "KMS key for Terraform state bucket encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 20
  policy = jsonencode({

    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [

      # Statement 1: Delegate full administrative control to Account IAM/Root
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*"
        Resource = "*"
      },

      # Statement 2: Allow terraform state s3 bucket to use the key for bucket operations
      {
        Sid    = "Allow S3 Service Use"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = "arn:aws:iam:::mgmt-admin-terraform-state-${data.aws_caller_identity.current.account_id}"
          }
        }

      }

    ]

  })
}

# 3. Create kms alias
resource "aws_kms_alias" "kms_alias" {
  name          = "alias/terraform-state-s3-kms"
  target_key_id = aws_kms_key.terraform_state_key.key_id
}

# 4. Create the S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket = "mgmt-admin-terraform-state-${data.aws_caller_identity.current.account_id}"

  force_destroy = false # Protects your state from accidental deletion

  lifecycle {
    prevent_destroy = true # Safeguard against accidental terraform destroy
  }
}

# 5. Enable Encryption using the created KMS key
resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true # Reduces KMS costs significantly
  }
}

# 6. Enable Versioning (Crucial for state file recovery)
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }

}

# 7. Block all Public Access to the State Bucket
resource "aws_s3_bucket_public_access_block" "state_privacy" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
