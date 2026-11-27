# CloudTrail closeout notes - Phase 2.3

**What shipped.** Organization trail `org-trail`, managed in `envs/organization`: multi-region, organization trail, global service events on, log-file validation on, management events read and write, data events off. Delivers to `cloudtrail-logs-408873346185` in Log Archive under `AWSLogs/o-4nhn73sdcv/`. Bucket and policy live in `envs/log-archive` and were applied first.

**Break-glass creation, recorded honestly.** This trail was not created by CI. After repeated CI failures, the trail and the `AWSServiceRoleForCloudTrail` service-linked role were created manually by the operator as management admin on 2026-11-21, then imported into Terraform state. CI manages the trail from the import forward. The manual creation also served as a bisector: it proved the organization, the trusted access, and the bucket policy were healthy, and isolated the fault to the CI path.

**Failure mode 1.** `InsufficientS3BucketPolicyException` (first seen 2026-11-20 22:06 ET): trail creation was attempted before the bucket policy was in place. Fixed by applying the bucket and its policy before the trail. Bucket before service.

**Failure mode 2.** `InsufficientDependencyServiceAccessPermissionException`: the CI apply role could not trigger creation of the CloudTrail service-linked role, despite the `iam:CreateServiceLinkedRole` grant being present and IAM simulation returning allowed. Root cause unproven. Prime suspect is trusted-access propagation timing within a single apply, where the trail raced the organization resource with no dependency edge. `depends_on = [module.aws_organization]` is now on the trail so a rebuild cannot race it.

**The logging gap.** Creating a trail through API does not start it; logging is a separate switch the console flips for you and the API does not. The imported trail therefore showed `enable_logging` changing from false to true in the CI apply on 2026-11-21 01:11 ET. Between the break-glass creation (about 1:00 ET) and that apply, the trail existed but delivered nothing. Events from that window exist only in per-account Event history, which retains 90 days, and not in this bucket.

**Correction recorded.** An earlier working claim held that the CloudTrail service-linked role exists only in the management account. It also exists in member accounts (verified in Prod), created service-linked through trusted access, not by any principal holding IAM authority in those accounts.

**Evidence in this folder.** `cloudtrail-trail-status.txt` (IsLogging true, latest delivery), `cloudtrail-bucket-org-path.txt` (all five account prefixes under the org path), `cloudtrail-dev-management-event.json` (the CloudTrail service assuming its role in Dev, session `CloudTrailOrganizationReplication`).
