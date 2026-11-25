resource "aws_config_organization_conformance_pack" "org_pack" {
  name               = "landing-zone-baseline"
  delivery_s3_bucket = aws_s3_bucket.conformance_pack_bucket.bucket
  template_body      = <<EOT
  Resources:
    CloudTrailEnabled:
      Type: AWS::Config::ConfigRule
      Properties:
        ConfigRuleName: CloudTrailEnabled
        Source:
          Owner: AWS
          SourceIdentifier: CLOUD_TRAIL_ENABLED
    VPCFlowLogsEnabled:
      Type: AWS::Config::ConfigRule
      Properties:
        ConfigRuleName: VPCFlowLogsEnabled
        Source:
          Owner: AWS
          SourceIdentifier: VPC_FLOW_LOGS_ENABLED
    EncryptedVolumes:
      Type: AWS::Config::ConfigRule
      Properties:
        ConfigRuleName: EncryptedVolumes
        Source:
          Owner: AWS
          SourceIdentifier: ENCRYPTED_VOLUMES
    S3AccountLevelPublicAccessBlocks:
      Type: AWS::Config::ConfigRule
      Properties:
        ConfigRuleName: S3AccountLevelPublicAccessBlocks
        Source:
          Owner: AWS
          SourceIdentifier: S3_ACCOUNT_LEVEL_PUBLIC_ACCESS_BLOCKS
    RootAccountMFAEnabled:
      Type: AWS::Config::ConfigRule
      Properties:
        ConfigRuleName: RootAccountMFAEnabled
        Source:
          Owner: AWS
          SourceIdentifier: ROOT_ACCOUNT_MFA_ENABLED
    IncomingSSHDisabled:
      Type: AWS::Config::ConfigRule
      Properties:
        ConfigRuleName: IncomingSSHDisabled
        Source:
          Owner: AWS
          SourceIdentifier: INCOMING_SSH_DISABLED
  EOT



}
