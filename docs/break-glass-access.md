# Break-Glass Access - Emergency Recovery Runbook

**Status:** Documented root recovery procedure
**Classification:** Security Operations
**Applies to:** AWS Organizations management account
**Owner:** Cloud Platform/Security
**Last reviewed:** 2026-11-12

## 1. Purpose
This runbook defines the exceptional circumstances, authorization requirements, and recovery steps for using AWS root credentials when normal administrative access is unavailable.

All routine workforce access is managed through **AWS IAM Identity Center**, using enforced multi-factor authentication (MFA), group assignments, and account-specific permission sets.

The management account root user is retained solely as an emergency recovery mechanism. It is not an alternative to IAM Identity Center or a mechanism for routime administration.

## 2. Authorized Activation Conditions
Break-glass access is permitted when:

1. **IAM Identity Center is unavailable:** An authentication or service disruption prevents administrators from accessing the AWS environment through the normal workforce access path.
2. **All administrators are locked out:** No authorized administrator can regain access through exisiting IAM Identity Center accounts, MFA recovery, or permission-set assignments.

Break-glass access must never be activated for convenience, faster deployment, troubleshooting that can be performed through existing roles, or bypassing access controls.

## 3. Emergency Identity and MFA

The designated emergency identity is the **AWS Organizations management account root user**, authenticated independently of IAM Identity Center.

| Control | Configuration |
| ------- | ------------- |
| Emergency principal | Management account root user |
| AWS Account | Management account ID |
| Root MFA | FIDO2/WebAuthn passkey or security key |
| Credential custody | Restricted, encrypted credential vault |
| Authorized operator | Designated account owner |
| Monitoring | AWS CloudTrail |
| Usage | Emergency recovery only |

The root password must be stored in an approved encrypted credential vault. MFA devices must be secured separately, with access restricted to authorized custodians.

Root credentials, MFA recovery material, and secrets must never be commited to this repository.

## 4. Emergency Recovery Procedure

### Step 1 - Verify the incident

* Confirm that IAM Identity Center is unavailable or all administrators are locked out.
* Rule out individual user, MFA, network, and permission-set configuration issues.
* Record the incident start time, symptoms, affected accounts, and troubleshooting evidence.
* Obtain explicit emergency authorization where available. If no approver is reachable, record the emergency justification for retrospective review.

### Step 2 - Access the management account

* Retrive root credentials through the approved secure custoday process.
* Open the official AWS root-user sign-in page.
* Authenticate using the management account root credentials and its registered MFA device.
* Record the operator identity and session start time in the incident record.

### Step 3 - Restore normal access

* Identify the cause of the administrative access failure.
* Perform only the minimum recovery actions required.
* Restore the IAM Identity Center administrative access path where technically possible.
* If IAM Identity Center itself is disrupted, follow AWS service recovery or escalation procedures rather than bypassing the outage with routine root administration.
* Confirm that an authorized administrator can regain access through the intended permission-set path.

### Step 4 - Terminate emergency access

* Stop using the root account immediately after recovery
* Sign out of the emergency session.
* Record the session end time and all changes performed.

## 5. Mandatory Post-Use Controls

The following actions are required after every break-glass activation:

[X] Rotate the management account root password and secure the new credential in the approved vault.
[X] Verify root MFA remains correctly registered; replace compromised or untrusted MFA devices.
[X] Review the complete root-user activity in AWS CloudTrail, including `ConsoleLogin`, API operations, timestamps, source IP addresses, and affected resources.
[X] Investigate and unexpected changes or unauthorized activity.
[X] Restore and validate IAM Identity Center access with MFA and the intended permission sets.
[X] Document the root cause, recovery actions, impact, and preventive measures.
[X] Obtain a post-incident security review and close the incident.

CloudTrail root sign-in events must be examined across the AWS sign-in logging Regions as applicable. Relevant evidence should be retained according to the organization's log-retention policy.

## 6. Explicitly Prohibited Practices

The following are prohibited:

* **No standing emergency sessions or routinely used privileged break-glass accounts.**
* **No root access keys** or distribution of long-lived AWS access credentials.
* **No credential sharing** through email, chat, tickets, repositories, or plaintext files.
* **No convenience access** to avoid IAM Identity Center authentication, MFA, or permission-set approvals.
* **No routine deployments, Terraform operations, or application administration** using root credentials.
* **No persistent workaround** that substitutes emergency access for the established IAM Identity Center permission-set model.
* **No unreviewed use:** Every activation must have an incident record and CloudTrail review.

The AWS root identity has inherent privileged authority. These restrictions control when that authority must be exercised; they do not imply that the root identity has been technically disabled.

## 7. Operational Readiness

The recovery process must be reviewed periodically to verify that credential custody, registered MFA devices, authorized operators, and emergency contact information remain accurate.

A tabletop exercise should validate the recovery sequence without requiring unnecessary root sign-ins.

For AWS Organizations member accounts, centralized root access management and a separate cross-account emergency recovery design should be evaluated and documented independently.

## 8. AWS References

* [Root user best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-best-practices.html)
* [IAM Identity Center emergency access](https://docs.aws.amazon.com/singlesignon/latest/userguide/emergency-access.html)
* [Centralized root access management](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_root-enable-root-access.html)
* [CloudTrail console sign-in events](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-event-reference-aws-console-sign-in-events.html)
