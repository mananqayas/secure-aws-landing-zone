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

# 8. Create OIDC provider trust with AWS
resource "aws_iam_openid_connect_provider" "github" {

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  tags = {
    Name = "github"
  }

}

# 9. Create IAM role for plan ci step
resource "aws_iam_role" "plan_role" {

  name = "plan_role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {

          "StringLike" = {
            "token.actions.githubusercontent.com:sub" = "repo:mananqayas@*/secure-aws-landing-zone@*:*"

          }

          "StringEquals" = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }

      }
    ]

  })
}

# 10. Attach the AWS Managed Policy using its static ARN
resource "aws_iam_role_policy_attachment" "managed_policy_attach" {
  role       = aws_iam_role.plan_role.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# 11. Create JSON data policy for S3 access to terraform state bucket
data "aws_iam_policy_document" "s3_policy_for_plan_role" {

  statement {

    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetObject"]
    resources = ["arn:aws:s3:::mgmt-admin-terraform-state-013310058149", "arn:aws:s3:::mgmt-admin-terraform-state-013310058149/*"]

  }
  statement {

    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = ["arn:aws:kms:ca-central-1:013310058149:key/4d4fee85-76f6-4b52-a1ec-11f79c983cf8"]
  }
}

# 12. Create IAM policy for s3 access
resource "aws_iam_policy" "s3_access_policy_plan_role" {

  name        = "s3-access-policy-for-plan-role"
  description = "Policy for terraform plan role to access s3 bucket for reading state file"
  policy      = data.aws_iam_policy_document.s3_policy_for_plan_role.json

}

# 13. Assign the IAM policy with terraform plan role

resource "aws_iam_role_policy_attachment" "custom_policy_attach" {
  role       = aws_iam_role.plan_role.name
  policy_arn = aws_iam_policy.s3_access_policy_plan_role.arn
}
