# Changelog

All notable decisions and changes, newest first. Conventional commits in git; this file is the human-readable decision log.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## [2.0.0] - 2026-11-08

### Added
* AWS Organization managed as code (Terraform + GitHub Actions): 3 OUs - Security, Workloads, Suspended - and 4 member accounts (Log Archive, Audit, Dev, Prod) in an AWS Security Reference Architecture Layout
* One-time local bootstrap creating the versioned, KMS-encrypted S3 state backend with lockfile, the GitHub OIDC identity provider, and the CI roles; all infrastructure after bootstrap is provisioned through CI.
* Two-role OIDC CI with no long-lived AWS credentials: a read-only plan role for pull requests, and an apply role restricted to `main` plus a protected `production` Environment - manual approval happens before any token is issued.
* Reusable account-baseline module applied to all four member accounts: per-account IAM permissions boundary, `terraform-plan` (ReadOnlyAccess) and `terraform-deploy` (custom least-privilege policy) roles, S3 account-level public access block, and EBS encryption by default in ca-central-1.
* Per-root Terraform state (one S3 key and lock per root) with a four-cell workflow matrix, so each member account plans and applies independently under its own short-lived credentials.
* Account graduation model: accounts are provisioned through OrganizationAccessAccessRole, then flipped to their permanent member roles; CI's standing OAA access was removed afterwards and the removal proven by a negative test denying both CI roles.
* ADR-0001 (delivery and identity architecture) and ADR-0002 (organization design), plus a Phase 2.0 evidence checklist tying each claim to its verification artifact.

### Security
* Every pipeline-created role must be born wearing the `terraform-boundary` permissions boundary, enforced by an iam:PermissionsBoundary condition on role creation and boundary-management actions are granted to no pipeline identity.
* `terraform-deploy` is fenced by a mirrored identity policy and a MemberProtect deny that blocks modification of the boundary, both pipeline roles, and OrganizationAccountAccessRole, while preserving the reads state refresh needs.
* The permissions boundary is also stamped onto OrganizationAccountAcessRole itself, capping the provisioning path once an account is baselined.
* State is encrypted with a customer-managed KMS key with automatic rotation; member accounts block all public S3 access at the account level.
