# Phase 2.3 - Guardrails, Logging & Detection Controls Verification
This directory contains implementation evidence for the guardrail layer established during Phase 2.3 of the Secure AWS Landing Zone.

The objective is to verify preventive controls that bind every member account (service control policies), an organization audit trail delivered outside the accounts it records, configuration recording in all five accounts, and one detective baseline (an organization conformance pack) whose first results, including its findings, are captured as evidence.

## Verification Summary

| Control | Observed result |
| ------- | --------------- |
| SCP set | Six SCPs defined in `envs/organization`; the Dev account's attached policy list is captured, and the negative-test battery below was executed against Dev |
| Leave organization on | Denied to an SSO administrator session in a member account |
| Region confinement | EC2 describe denied in us-east-1 and working on ca-central-1 from the same session |
| Encryption requirement | Unencrypted EBS volume creation denied; encrypted volume creation succeeded |
| Suspended OU | Deny-all policy attached to the Suspended OU |
| Logging protection | Stopping the configuration recorder explicitly denied by the ProtectLogging SCP |
| Organization trail | `org-trail` logging on; delivered objects present under all five account prefixes on the organization path (`AWSLogs/<org-id>/<account-id>/`) |
| Config recording | Recorder module live in all five accounts, delivering configuring history to the central |
| Conformance pack | `landing-zone-baseline` CREATE_SUCCESSFUL in all five accounts (per-account detailed status saved) |
| Baseling compliance | CloudTrailEnabled and IncomingSSHDisabled COMPLIANT in all five accounts; S3AccountLevelPublicAccessBlocks compliant where evaluated; EncryptedVolumes has no resources in scope in any account |
| Finding 1 | VPCFlowLogsEnabled NON_COMPLIANT in all five accounts, one resource each: the AWS-created default VPC. The module-built VPCs in Dev and Prod are compliant. |
| Finding 2 | RootAccountMFAEnabled COMPLIANT in the management account; in member accounts the rule is ACTIVE and evaluates successfully but records no result (see Evidence Index 3 and ADR-0005) |

## Evidence Index

1. Service control policies

| Evidence | Verification |
| -------- | ------------ |
| [Dev account SCP list](./dev-account-scp-list.json) | The policies attached to the Dev account, including the five guardrails |
| [Leave-organization denied](./cloudtrail-event-deny-org-leave.json) | The CloudTrail event for the denied `LeaveOrganization` call from a member account |
| [Leave-organization denied, CLI session](./cloudtrail-event-deny-org-leave.json) | The same denial from the operator's SSO administrator session in Dev |
| [EC2 describe denied outside the home region](./ec2-describe-denied-in-us-east-1.png) | RegionAllowList refusing EC2 calls in us-east-1 |
| [EC2 describe working in the home region](./ec2-describe-instances-works-in-home-region.png) | The control case: the same call succeeding in ca-central-1 |
| [Unencrypted volume creation denied](./deny-creating-ec2-volumes-without-encryption.png) | RequireEncryption refusing an EBS volume with no encryption requested |
| [Encrypted volume created](./ebs-volume-created-with-encryption-enabled.png) | The control case: an encrypted volume created successfully |
| [Deny-all on the Suspended OU](./deny-all-applied-to-suspended-ou.png) | SuspendedDenyAll attached to the Suspended OU |
| [StopConfigurationRecorder denied](./explicit-deny-to-stop-configuration-recorder.png) | ProtectLogging refusing to stop a Config recorder. The same policy makes a future Terraform destroy of a recorder fail by design |

2. Organization CloudTrail

| Evidence | Verification |
| -------- | ------------ |
| [Trail status](./cloudtrail-trail-status.txt) | `org-trail` configuration and `isLogging: true` |
| [Delivery bucket organization path](./cloudtrail-bucket-org-path.txt) | Delivered objects in the Log Archive bucket under the organization path for all five account |
| [Dev management event](./cloudtrail-dev-management-event.json) | A management event from Dev captured in the delivered logs |
| [Closeout notes](./cloudtrail-closeout-notes.md) | The creation sequence as it actually happened: two failed CI attempts, one break-glass creation of the service-linked role and trail, import into state, and a CI apply enabling logging, with the resulting logging gap and the unproven trust-access timing hypothesis stated plainly |

3. AWS Config and the conformance pack

| Evidence | Verification |
| -------- | ------------ |
| [Pack detailed status](./config-pack-detailed-status.json) | Per-account deployment status for `landing-zone-baseline`: UPDATE_SUCCESSFUL in all five accounts |
| [Aggregate compliance](./config-compliance-aggregate.json) | The organization-wide compliance query against `org-config-aggregator`, unfiltered: every rule result the aggregator holds, including both findings below |
| [Root MFA evaluation status, Dev](./root-mfa-evaluation-status-dev.json) | `describe-config-rule-evaluation-status` for Dev's RootAccountMFAEnabled and CloudTrailEnabled copies. CloudTrailEnabled was invoked at deployment (10:34:21) and evaluated successfully. RootAccountMFAEnabled was activated at 10:34:00 and invoked exactly once, at 14:15:41 on 2026-11-25, evelen seconds after a manual StartConfigRulesEvaluation call (CloudTrail event `b37c4563-dced-4b44-9e30-a33bfcf229b1`), with the invocation and evaluation both successful and no compliance result recorded |

**Finding 1, default VPCs:** VPCFlowLogsEnabled reports exactly one noncompliant resource in each of the five accounts. In each case the resource is the default VPC AWS created with the account. Independent corroboration: the management account's first configuration-history delivery contains the full anatomy of a default VPC (VPC, subnets, security group, network ACL, route table, internet gateway, DHCP options, CIDR block, gateway attachment) and no other VPC. The VPCs built by `modules/vpc` in Dev and Prod have flow logs and are compliant. Disposition is ADR-0005: accepted for this phase; deleting the default VPCs is a separate follow-up change.

**Finding 2, member root MFA:** RootAccountMFAEnabled is COMPLIANT in the management account, whose root user is in active use with MFA enabled. In the member accounts the rule is deployed and ACTIVE and, as the Dev status above shows, evaluates successfully, but records no compliance result. The behavior is consistent with the member root users being dormant: created by AWS Organizations, never give a password, never signed in, so there is no root credential state to attach a verdict to. Disposition in ADR-0005: accepted. The condition the rule guards is structurally prevented in members by the DenyRootInMembers SCP and by the absence of root credentials.

**Redaction:** the operator's home IP address is replaced with `<home-ip>` in the committed CloudTrail event extracts, and the session token present in the raw Dev management event is replaced with `<redacted>`. Account IDs are not redacted; they are part of the evidence's meaning.

## Security Decisions
* **Prevention and detection are separate layers on purpose:** SCPs bind member accounts but cannot reach the management account and cannot report drift; the conformance pack covers all five accounts and reports. Each layer's findings justify the other.
* **Logs and archives live elsewhere:** the CloudTrail bucket and the Config archive bucket are both in the Log Archive account, which the recorded accounts cannot modify.
* **Aggregation is delegated, not centralized in management:** the Audit account holds both delegated-administrator registrations and the aggregator, keeping security operations out of the organization's control plane.
* **A clean plan is not a deployment proof:** the pack's Terraform resource showed no changes while its management-account deployment had failed; the gate evidence for the pack is the per-account detailed status, not a plan output.
* **Findings are evidence, not failures:** both baseline findings shipped in this evidence set with dispositions recorded in ADR-0005, rather than being remediated quietly before the phase closed.

The rationale for these decisions is documented in [ADR-0005](.../../adr/0005-guardrails-and-detective-controls.md)

**Result:** Phase 2.3 evidence demonstrates six SCPs with a live negative-test battery, an organization trail delivering for all five accounts to a bucket outside their control, configuration recording in every account, and a six-rule detective baseline deployed to all five accounts with its complete first compliance picture, two findings included and dispositioned.
