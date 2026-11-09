# ADR 0001: Deployment and Identity Architecture for AWS Landing Zone

Date: 2026-11-08

Status: Accepted

## Context
We are establishing an automated, multi-account AWS Landing Zone managed via Terraform and orchestrated by GitHub Actions. The core requirement is to implement a resilient, automated GitOps framework that adheres to absolute zero-trust principles. To achieve this, we must solve several critical architectural challenges:

1. **Long-Live Credentials:** We must completely eliminate static, high-privilege AWS Access Keys inside our CI/CD platform to protect against credential leaks.

2. **Privilege Escalation:** Automated pipelines executing code changes in member accounts could accidently or maliciously modify their own IAM rights to bypass organizational guardrails.

3. **Bootstrap Chicken-and-Egg Dilemma:** Automated cross-account deployment roles cannot exist until they are created, requiring a secure, audited mechanism to instantiate the landing zone's foundation.

4. **State Exfiltration and Tampering:** A unified Terraform state file or shared encryption key allows a compromised low-tier environment (e.g., Dev) to read or tamper with high-tier environment configurations (e.g., Prod).

## Options Considered

### Option 1: Monolithic Deployment Identity with Universal State Access
Utilize a single, highly privileged IAM role assumed via OIDC across all branches, storing all account state files in a single S3 bucket sharing a master KSM key.

* *Pros:* Low operational complexity; highly straightforward GitHub Actions configurations.
* *Cons:* Severe blast-radius risk. Any feature branch or unreviewed pull request could alter production state, escalate its own privileges, or mutate real-world infrastructure.

### Option 2: Split OIDC Identities, Managed Bootstrapping, and Cryptographically Isolated State (Chosen)
Implement dual-role OIDC federation (Read-Only Plan / Scoped Apply), a multi-phase bootstrap sequence leveraging temporary OrganizationAccountAccessRole (OAAR) privileges, explicit AWS Permissions Boundaries appended to all generated roles, and distinct state file boundaries.

* *Pros:* Enforces absolute least privilege; completely prevents escalation; strictly limits blast radius across environments; cryptographically seals state data per environment.
* *Cons:* Significant engineering overhead; complex multi-stage pipeline orchestration; requires strict state management and precise KMS key policy maintenance.

## Decision
We selected **Option 2**. The security mandate of a resilient multi-account landing zone necessitates a robust governance engine that actively prevents privilege escalation, isolates environments at the state layer, and permanently decommissions human/root access post-bootstrap.

## Implementation Specifics
* **Dual-Role OIDC Trust:** GitHub Actions authenticates via OpenID Connect. Feature branch pushes assume a read-only `plan-role` role. Merges to the `main` branch require a GitHub Production Environment manual approval gate escalating to the `apply-role` role. 
* **The Bootstrap Sequence Exception:** Initial infrastructure is stood up by a human administrator leveraging temporary AWS IAM Identity Center (SSO) Administrator privileges. The Management Account's `apply-role` pipeline uses this access to assume the native `OrganizationAccountAccessRole` (OAAR) inside new member accounts.
* **The "Born-With-Boundary" Pattern:** The management pipeline use its OAAR access to construct localized `terraform-plan` and `terraform-deploy` roles inside the member accounts. Crucially, every role created is appended with a `terraform-boundary` **Permissions Boundary**. This boundary strictly dictates that the deployment engine can never delete core security controls, alter its own boundary, or escalate its permissions.
* **Dismantling Bootstrapping Access:** Once member account baselines and roles are fully instantiated, the global OAAR trust and human SSO admin access are **permanently removed**. Day-2 operations rely exclusively on the Management Account's `apply-role` role assuming the newly minted, boundary-restricted member roles.
* **State Isolation:** Terraform states are segregated into specific paths, org, bootstrap, and members.

## Trade-offs & Consequences
* **Zero Static Credentials:** Eliminiating long-lived access keys neutralizes the single greatest vector for cloud repository breaches.
* **Immunized Against Privilege Escalation:** Because of the `terraform-boundary` pattern, even a rogue or compromised Terraform script running in the pipeline cannot alter IAM boundaries to give itself global admin access.
* **Strict Blast Radius Reduction:** Compromising a feature branch or a Dev account provides zero visibility or leverage into the Prod environment or the core Management state files.
* **Audit-Ready Posture:** Separating roles by action (`plan` vs `apply`) maps perfectly to the standard corporate compliance requirements (e.g., SOC2 Type II, ISO 27001) regarding separation of duties.

## Negative (The "Taxes" Paid)
* **High CI/CD Complexity:** GitHub workflows must be delicately configured to split jobs across environments, managed discrete OIDC tokens, and elegantly handle human approval interruptions.
* **Bootstrapping Maintenance:** Adding a new account requires executing a specific, highly coordinated phased pipeline before it can transition smoothly into standard Day-2 GitOps automation.
* **Permissions Boundary Overhead:** Any future architecture expansion requiring the deployment pipeline to provision new types of IAM roles means the underlying `terraform-boundary` policy must be meticulously updated and maintained, slightly slowing down baseline expansions.
