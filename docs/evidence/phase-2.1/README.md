# Phase 2.1 - Workforce Identity & Access Verification
This directory contains implementation evidence for the workforce identity and access controls established during Phase 2.1 of the Secure AWS Landing Zone.

The objective is to verify centralized workforce authentication through AWS IAM Identity Center, group-based authorization across AWS accounts, MFA enforcement, and the IAM credential baseline for organization accounts.

## Verification Summary

| Control  | Observed result |
| -------- | --------------- |
| Centralized workforce authentication | AWS IAM Identity Center access portal operational |
| MFA enforcement | MFA configured for every sign-in; invalid code rejected |
| Group-based authorization | `PlatformAdmins`, `Developers`, `ReadOnlyAuditors` |
| Administrative access | Platform administrator portal displays five accounts |
| Developer isolation | Developer test identity displays only Dev |
| Production access probe | Attempted Developers role switch into Prod rejected |
| SSO role provisioning | AWS SSO role creation events recorded in CloudTrail |
| Root credential baseline | Four member accounts without root passwords access keys |
| Management root | Password enabled, MFA active, no active access keys |

## Evidence Index

### 1. Authentication & MFA

| Evidence | Verification |
| -------- | ------------ |
| [MFA configuration](./identity-auth-mfa-enforced.png) | Identity Center configured to prompt for MFA every sign-in; with MFA registration required |
| [Incorrect MFA rejected](./sign-in-failed-for-incorrect-mfa.png) | Invalid MFA code rejected during authentication |

### 2. Authorization & Account Isolation

| Evidence | Verification |
| ----- | --------------- |
| [Account assignments](./account-assignments.txt) | Group-based permission-set across organization accounts |
| [Platform administrator portal](./sign-in-as-platform-admin.png) | Administrative access portal displays all five AWS accounts |
| [Developer access portal](./dev-probe-access-portal.png) | Developer test identity displays only the Dev account |
| [Production negative probe](./dev-probe-negative-test-prod.png) | Attempt to switch to a Developers role in Prod fails  |

The account-assignment export records the following access model:

| Group | Account scope |
| ----- | ------------- |
| PlatformAdmins | Management, Audit, Log Archive, Dev, Prod |
| ReadOnlyAuditors | Management, Audit, Log Archive, Dev, Prod |
| Developers | Dev only |

Access is granted through Identity Center group-to-permission-set-to-account assignments rather than direct per-user AWS account assignments.

**Negative-test limitation:** The Production screenshot shows an unsuccessful role-switch attempt with an invalid-information error. Combined with the account-assignment export and developer portal, this supports the intended account boundary. The error alone is not definitive proof of an *IAM AccessDenied* decision.

### 3. Identity Center Role Provisioning

| Evidence | Verification |
| -------- | ------------ |
| [SSO provisioning events](./sso-provisioning-actor-dev.png) | CloudTrail records CreateRole events associated with AWS SSO provisioning in Dev |

This provides an audit trail of Identity Center's provisioning of IAM roles used for account access.

### 4. IAM Credential Baseline

IAM credential reports were exported independently from each AWS account.

| Account | Evidence | Root password | Root MFA | Root access keys |
| ------- | -------- | ------------- | -------- | ---------------- |
| Management | [CSV](./credential-report-management.csv) | Enabled | Active | None |
| Log Archive | [CSV](./credential-report-log-archive.csv) | Disabled | Inactive | None |
| Audit | [CSV](./credential-report-audit.csv) | Disabled | Inactive | None |
| Dev | [CSV](./credential-report-dev.csv) | Disabled | Inactive | None |
| Prod | [CSV](./credential-report-prod.csv) | Disabled | Inactive | None |

Each exported report contains only the root-account entry and shows no active IAM access keys.

The member-account results are consistent with AWS Organizations accounts created without root passwords. `mfa_active=false` in these reports should not be treated as an MFA enforcement failure when the corresponding root password is disabled.

Management-account root remains independently accessible and MFA-protected for emergency recovery and root-required operations.

These reports do not establish that AWS centralized root access management or privileged root sessions have been enabled.

## Security Decisions
* **Centralized identity:** IAM Identity Center is the standard entry point for workforce access.
* **Group-based authorization:** Account access is assigned to groups rather than individual users.
* **Separation of duties:** Developer, administrator, and auditor access are represented by distinct groups and permission sets.
* **MFA enforcement:** Workforce authentication requires a second factor.
* **No standing IAM keys:** Routine human access uses Identity Center sessions rather than permanent IAM user credentials.
* **Emergency recovery:** Management-account root access remains separate from the workforce authentication path and is governed by the break-glass procedure.

The rationale for these decisions is documented in [ADR-0003](../../adr/0003-workforce-identity-and-access-model.md)

**Result:** Phase 2.1 evidence demonstrates centralized workforce identity configuration, MFA enforcement behavior, group-based account access, recorded SSO provisioning activity, and the observed IAM credential baseline across five AWS accounts.
