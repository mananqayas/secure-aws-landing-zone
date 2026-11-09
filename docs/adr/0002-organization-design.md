# ADR 0002: Organizational Unit (OU) and Account Architecture Design

Date: 2026-11-08

Status: Accepted

## Context
To host our workloads securely and at scale, we require a robust multi-account strategy using AWS Organizations. Managing enterprise infrastructure under a single AWS account introduces significant blast radius, chaotic IAM resource policy management, and lack of strict environment isolation.

We must establish a structural blueprint that adheres to the **AWS Security Reference Architecture (SRA)** while aligning with specific operational constraints:

1. **Separation of Concerns:** Security operations and log archiving must be strictly isolated to prevent internal or external tampering.

2. **Account Lifecycle & Portfolio Constraints:** Because this is a reference portfolio project, we need an automated, intentional way to destroy non-production infrastructure to control costs, while demonstrating production-grade safety flags on production data.

3. **Regional Governance:** To comply with data residency goals and optimize architecture complexity, we must pin our footprint down to a specific primary region.

## Options Considered

### Option 1: Monolithic Flat Organization
Deploy a single organizational structure with single accounts containing mixed environments (Dev/Prod) and unified log/security monitoring setups.

* *Pros:* Simple to orchestrate via Terraform; minimal multi-account cross-role configuration overhead.
* *Cons:* Severe violation of AWS SRAl compromised developer instances can sniff production traffic or access centralized logs; high blast radius.

### Option 2: AWS SRA-Aligned 3-OU Pattern with Functional Separation and Lifecycle Controls (Chosen)
Implement a streamlined AWS SRA pattern utilizing exactly 3 OUS (`Security`, `Workloads`, `Suspended`), dedicated decoupled core accounts (`Log Arhive`, `Audit`), localized deployment home-region constraints (`ca-central-1`), and explicit account termination behaviors.

* *Pros:* Absolute alignment with AWS top-tier security standards; hard boundary enforcement between security monitoring and raw data logs; strict protection against accidental cloud spend and state drift via aggressive non-production lifecycle teardown controls.
* *Cons:* Higher complexity in organizational drift tracking; requires configuring multiple landing zone cross-account role handshakes.

## Decision
We selected **Option 2**. The organization is constructed with a highly deliberate blueprint utilizing the native **AWS IAM Identity Center (SSO)** for centralized workforce authentication and directory management, pinned explicitly to the **`ca-central-1` (Canada Central)** home region.

### Implementation Specifics

```
Root
├── 🛡️ Security OU
│    ├── Log Archive Account (Raw, immutable security logs)
│    └── Audit Account (Active security tools: GuardDuty, Security Hub)
├── 🏗️ Workloads OU
│    ├── Dev Account
│    └── Prod Account
└── 🛑 Suspended OU (Quarantine zone / Deny-All SCP incoming in Phase 2.3)
```
1. **Strict Decoupling of Security Accounts (`Log Archive` `Audit`):**

Following the AWS SRA blueprint, the `Log Archive` and `Audit` accounts are completely split.

* The **Log Archive account** acts as a strictly read-only, tamper-proof bucket store for centralized organization-wide trails (CloudTrail, VPC Flow Logs).
* The **Audit account** hosts our security orchestration engine (Amazon GuardDuty, AWS Security Hub).
* **The Guardrail:** If an attacker gets into the Audit account, they are cryptographically and structually blocked from deleting or altering the logs stored inside the Log Archive account.


2. **The 3-OU Layout & Account Lifecycle Safety:**

* **Security OU:** Houses our core protection layers (`Log Archive` and `Audit`).
* **Workloads OU:** Segregates our application (`Dev` and `Prod`).
* **Suspended OU:** Dedicated as a dynamic quarantine zone. In Phase 2.3, a structural `Deny-All` Service Control Policy (SCP) will be attached here to lock down compromised or decommissioned accounts instantly.

3. **Intentional Account Lifecylce Flag (`close_on_termination`):**

* To fit the realistic needs of a cloud portfolio architecture, the **`Dev` and management infrastructure accounts have `close_on_termination = true`** toggled in their Terraform configurations. This allows the automated CI/CD pipeline to rapidly spin down and securely clean up sandbox spaces to elimiated tail costs.
* Conversely, the **`Prod` workload account has `close_on_termination = false`** explicitly enforced. This simulates production safety guidelines, ensuring that a human error or a bug in a pipeline script can never accidently drop our primary production database or infrastructure.

## Trade-offs & Consequences

### Positive (Benefits)

* **AWS SRA Compliance:** The structure mirrors modern cloud-native security frameworks, which immediately signals enterprise-level competence to external auditors or architectural reviewers.
* **Blast Radius Immunization:** A security breach inside the `Dev` account cannot cross the boundary into `Prod`, nor can it compromise the integrity of security monitoring tools or historical log streams.
* **Cost and Safety Balance:** Using `close_on_termination` dynamically across environments showcases a deep understanding of operational realities-cost-optimized for portfolio lifecylces in non-prod, but heavily armored against accidental destruction in production.

### Negative (The "Taxes" Paid)

* **Cross-Account Logging Multipliers:** Routing logs from `Dev`, `Prod`, and `Audit` into a single central `Log Archive` requires detailed cross-account S3 bucket policies and strict KMS key-sharing policies.
* **Regional Strictness:** Constraining operations strictly to `ca-central-1` requires building additional guardrails (via future SCPs) to actively deny resource provisioning in all other global regions, introducing minimal management maintenance.
