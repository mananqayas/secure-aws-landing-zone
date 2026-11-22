resource "aws_cloudtrail" "org_trail" {
  depends_on                 = [module.aws_organization]
  name                       = "org-trail"
  enable_log_file_validation = true
  is_multi_region_trail      = true
  is_organization_trail      = true
  s3_bucket_name             = "cloudtrail-logs-408873346185"
}
