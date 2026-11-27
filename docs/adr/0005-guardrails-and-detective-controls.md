# ADR-0005: Organization Guardrails, Centralized Logging, and Detective Controls

Date: 206-11-25
Status: Accepted

## Context
The landing zone has accounts, identity, and networks (Phase 2.0 to 2.2), but nothing yet prevents an operator or a compromised principal from leaving the organization, working in the wrong region, turning off logging, or using a member account's root user, and nothing detects drift from the intended security posture after the fact. Phase 2.3 adds the guardrail layer in three parts: preventive controls (service control policies), a tamper-resistant audit trail (an organization CloudTrail), and detective controls (AWS Config recording, aggregation, and a conformance pack).

The design must provide:

* Preventive controls that bind every member account regardless of what any in-account administrator does, with the management account consciously out of SCP scope (AWS never applied SCPs to it).
* An audit trail whose storage sits outside the accounts it records, so a workload account cannot erase its own history.
* A single organization-wide view of configuration and compliance, operated from the Audit account rather than the management account, keeping day-to-day security operations out of the organization's control plane.
* Detective rules deployed identically to every account from one definition, so compliance results are comparable across accounts.
* Honest handling of first-run findings: a newly deployed baseline is expected to find real gaps, and the findings are part of the deliverable, not a deployment failure.

## Decision

**Attach six service control policies in envs/organization; run one organization CloudTrail delivering to a dedicated bucket in the Log Archive account; record configuration in every account with a shared recorder module; delegate AWS Config administration to the Audit account; aggregate there; and deploy one organization conformance pack, landing-zone-baseline, carrying six AWS managed rules to all five accounts.**

1. Service control policies
* Six SCPs are defined as resources in envs/organization: DenyLeaveOrganization, RegionAllowList, RequireEncryption, ProtectLogging, DenyRootInMembers, and SuspendedDenyAll. The first five attach to the workload accounts (Dev and Prod); SuspendedDenyAll attaches to the Suspended OU alone.
* RegionAllowList denies any action outside ca-central-1, with a NotAction carve-out for global services. The carve-out list is load-bearing and was corrected during the build: five CloudTrail read actions had to be added after the policy blocked the operator's own *lookup-events* calls against the global endpoint in us-east-1. A region deny that breaks the operator's ability to inspect logs is a finding against the policy, not against the operator.
* RequireEncryption covers EBS and RDS only. It is deliberately carries no *s3:PutObject* encryption deny: S3 encrypts new objects by default, and a deny would break third-party log delivery paths that cannot set the required headers.
* ProtectLogging denies stopping or deleting the organization trail and stopping or deleting Config recorders and delivery channels. One consequence is accepted by design and recorded here: a future Terraform destroy of a configuration recorder will be refused by this policy. Recorder teardown, if ever needed, is a deliberate policy change first, not an apply.
* DenyRootInMembers denies root-user actions in member accounts. Member root users are dormant (see Finding 2), and this policy is their compensating control.

2. Organization CloudTrail
* One trail, *org-trail*, defined in `envs/organization`: organization trail, multi-region, global service events on, log file validation on, management events read and write, data events off.
* Delivery is to a dedicated bucket in the Log Archive account with SSE-S3, a public access block, a deny on non-TLS transport, and lifecycle transition to Glacier at 90 days and expiry at 365 days. Organization trails deliver under *AWSLogs/<organization-id>/<account-id>*, and the bucket policy's write statements are written against that path shape.
* The trail's creation history is recorded in the Phase 2.3 evidence closeout notes rather than smoothed over here: CI creation failed twice, the service-linked role and trail were created once through the break-glass path, the trail was imported into state, and a CI apply then enabled logging. Events from the window between creation and the enabling apply exist only in per-account Event history (90 days). The suspected cause, a trusted-access timing race, is recorded as unproven.

3. AWS Config recording
* A reusable module, `modules/config-recorder`, is instantiated in all five accounts: a Terraform-managed service-linked role for Config, a configuration recorder (all supported resource types, global resource types included), a delivery channel, and the recorder started.
* Recorders deliver configuration history and snapshot to a central bucket in the Log Archive account. The delivery channel delivers exactly two artifact kinds, ConfigHistory (batched per resource type on a six-hour cycle) and ConfigSnapshot (on demand only); compliance results are not a delivered artifact and are read from the Config service and the aggregator, which is where this phase's compliance evidence comes from.
* Two service-linked-role failure modes from the build are recorded as standing rules for any future SLR work in this repository. A create that succeeds in AWS while its post-create read is denied leaves the resource tainted; the repair is to land the missing grant and untaint, never to let the resource replace, because the role is healthy and *iam:DeleteServiceLinkedRole* is granted nowhere. The complete grant set for a service-linked role managed by a boundary-wearing principal is three statements in both the identity policy and the permissions boundary: CreateServiceLinkedRole on the exact role ARN fenced by the service name, the GetRole read family on the exact ARN with no condition, and PassRole on the exact ARN fenced by the passed-to-service.

4. Delegated administration and aggregation
* The Audit account is registered as delegated administrator for both Config principals, config.amazonaws.com (aggregation) and config-multiaccountsetup.amazonaws.com (organization rules and conformance packs). Borh registrations are required; either one alone is insufficient.
* The organization aggregator, `org-config-aggregator`, lives in Audit. Its source role is a dedicated custom role, `terraform-config-aggregator`, with the AWS managed policy `AWSConfigRoleForOrganizations` attached. The Config service-linked role cannot serve as the aggregator's role: it lacks the Organizations List and Describe permissions the aggregator needs to discover member accounts. An earlier draft of this design specified the service-linked role and was corrected against the AWS documentation before it was built.
* Aggregation reads live configuration state from each account's Config service. The archive bucket is not an aggregation source; the delegated administrator's view and the archive are separate paths with separate latencies, and the evidence in this phase cites each for what it actually proves.

5. Conformance pack
* One organization conformance pack, `landing-zone-baseline`, is deployed from Audit. Its template carries six AWS managed rules: `CLOUD_TRAIL_ENABLED`, `VPC_FLOW_LOGS_ENABLED`, `ENCRYPTED_VOLUMES`, `S3_ACCOUNT_LEVEL_PUBLIC_ACCESS_BLOCKS`, `ROOT_ACCOUNT_MFA_ENABLED`, and `INCOMING_SSH_DISABLED`. The pack name is deliberate: the pack is the landing zone's minimum detective floor, the third baseline layer alongside the account-baseline module (provisioning) and the SCPs (prevention).
* Pack deployment stages templates through a dedicated bucket in Audit whose name carries the mandatory`awsconfigconforms` prefix, because the deployment service-linked role's managed policy reaches only buckets with that prefix. The bucket policy fences access by organization ID and by the deployment role's ARN pattern.
* Delegated administration has one sharp edge, learned during this build and recorded for any future pack work: when a delegated administrator deploys an organization conformance pack, AWS Config does not automatically create the deployment service-linked roles (ConfigConforms and ConfigMultiAccountSetup) in the management account, and deployment to the management account fails until they exist. Both roles were created in the management account through `envs/organization` (PR # 144), and the pack then deployed to all five accounts.
* The first pack apply also outran the Terraform provider's ten-minute waiter (last state CREATE_IN_PROGRESS) and left the resource tainted. The recovery pattern, recorded for reuse: fix the root cause, untaint the resource, confirm a no-change plan (a clean plan proves the definition matches, not that the deployment succeeded), and re-issue the deployment once with an identical template through the CLI. The pack reached CREATE_SUCCESSFUL in all five accounts.

## Findings at deployment
* **CloudTrailEnabled and IncomingSSHDisabled: COMPLIANT in all five accounts.** S3AccountLevelPublicAccessBlocks: compliant in every account where it has evaluated. EncryptedVolumes: no evaluation results anywhere, because no EBS volumes exist in any account; the rule has nothing in scope.
* **Finding 1, VPCFlowLogsEnabled: NON_COMPLIANT in all five accounts, exactly one resource each.** The noncompliant resource in each account is the AWS-created default VPC, which has no flow logs. The VPCs built by this landing zone in Dev and Prod have flow logs enabled and are complaint. Disposition: accepted for Phase 2.3 and recorded here; deleting the default VPCs is a follow-up change of its own, not folded into this phase's closeout.
* **Finding 2, RootAccountMFAEnabled: COMPLIANT in the management account; no result recorded in member accounts.** The member copies of the rule are deployed and ACTIVE. In Dev the rule's evaluation statusshows a single invocation, at 2026-11-25T14:15:41-05:00, eleven seconds after a manual StartConfigRulesEvaluation call (CloudTrail event `b37c4563-dced-4b44-9e30-a33bfcf229b1`), with the invocation and evaluation both successful and the account's compliance details still empty afterward. The behavior is consistent with the member root users being dormant; they were created by AWS Organizations, have never had a password set, and have never signed in, so the evaluation has no root credential state to attach a verdict to. The management root is in active use with MFA enabled and produced a normal result. Disposition: accepted. The condition this rule guards, root sign-in without MFA, is structurally prevented in member accounts by the DenyRootInMembers SCP and by the absence of root credentials. The evaluation-status output is saved with the Phase 2.3 evidence.

````mermaid
flowchart TB
    SCPs["envs/organization <br> 6 SCPs, org trail, delegated admin"]
    SCP_BIND["Dev, Prod, Log Archive, Audit"]
    SCPs -- "SCPs bind" --> SCP_BIND

    ORG_TRAIL["org-trail <br> (organization, multi-region)"]
    CLOUDTRAIL_BUCKET["CloudTrail bucket <br> Log Archive"]
    ORG_TRAIL --> CLOUDTRAIL_BUCKET
    RECORDER["Recorder module x5 accounts"]
    CONFIG_BUCKET["Config archive bucket <br> Log Archive"]
    RECORDER --> CONFIG_BUCKET

    AUDIT_ACCT["Audit account"]
    AGGREGATOR["org-config-aggregator role: terraform-config-aggregator"]
    CONFORM_PACK["Conformance pack <br> landing-zone-baseline, 6 rules"]
    ACCOUNTS["All 5 accounts"]
    AUDIT_ACCT --> AGGREGATOR & CONFORM_PACK
    AGGREGATOR -. "reads live state file" .-> ACCOUNTS
    CONFORM_PACK -. "deploys a rule copy into" .-> ACCOUNTS
`````
## Alternative considered

| Alternative | Reason not selected |
| ----------- | ------------------- |
| SCPs only, no Config | Preventive without detection; nothing would report drift in accounts when an SCP does not reach, and the management account is outside SCP scope entirely. The pack's two findings are exactly what an SCP-only design would never have surfaced. |
| Config rules deployed per account by Terraform | Five copies of every rule definition to keep in step. The conformance pack is one definition deployed by the service, and its per-account copies carry a uniform naming pattern the aggregator can query. |
| Aggregator in the management account | Works, but puts daily security operations in the organization's control plane. Delegated administration to Audit matches the account layout chosen in ADR-0002. |
| Aggregator role: the Config service-linked role | Not possible. The service-linked role lacks Organizations permissions aggregation requires; a dedicated role with AWSConfigRolForOrganizations is the documented shape. |
| Per-account Config archive buckets | Each account would hold its own evidence and a compromised account could delete it. The archive pattern in this landing zone is a central bucket under a separate account's control. |
| Delete the default VPCs as part of this phase | The finding is recorded and the remediation is small, but it is an infrastructure change in five accounts; it gets its own change and its own evidence rather than riding along with a closeout. |
| Set password and MFA on member root users so the rule can evaluate them | Creates live root credentials in accounts designed to have none, increasing risk to satisfy a check. The compensating controls (DenyRootInMembers, no root credentials) are the safer posture, and the finding records the reasoning. |

## Consequences

**Positive:** Every member account is bound by the same preventive floor; the audit trail and the configuration archive both live outside the accounts they record; one aggregator query returns the whole organization's compliance position; the baseline's first run produced a verified compliance picture (four rules reporting, two findings, both dispositione) within a day of deployment.

**Trade-offs:** ProtectLogging makes recorder and trail teardown a two-step act of policy change plus apply, permanently; pack deployments depend on service-linked roles existing in every target account including the management account, a prerequisite that must be re-checked if accounts are added; the S3 configuration archive trails live state by up to six hours, so it is a record, not a monitoring source; and one pack rule (RootAccountMFAEnabled) is accepted as non-reporting in member accounts for as long as their root users stay dormant, which is the intended posture.

## Verification and review

* SCP negative-test battery executed in Dev: leave-organization denied, cross-region EC2 calls denied while home-region calls succeed, unencrypted volume creation denied and encrypted creation successful, stopping the configuration recorder denied. Evidence in the Phase 2.3 evidence folder.
* Trail status shows logging on; the delivery bucket holds objects under all five account prefixes on the organization path; a Dev management event was captured from the delivered logs.
* Pack detailed status shows UPDATE_SUCCESSFUL for all five accounts; the aggregatre compliance query output and the Dev evaluation-status output for RootAccountMFAEnabled are saved with the evidence.
* Revisit this ADR if a member account's root user is ever given credentials, if the default VPCs are deleted (Finding 1 closes), if a second region is admitted, or if Access Analyzer is delegated to Audit as a companion detective control.

## References

* [AWS - Service control policies](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)
* [AWS - Organization trails](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-concepts.html)
* [AWS - How AWS Config works (delivery: history files and snapshots only)](https://docs.aws.amazon.com/config/latest/developerguide/how-does-config-work.html)
* [AWS - Organization aggregators and delegated administrator](https://docs.aws.amazon.com/config/latest/developerguide/aggregate-data.html)
* [AWS - Organization conformane packs](https://docs.aws.amazon.com/config/latest/developerguide/WhatIsConfig.html)
