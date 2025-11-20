# Architectural Decisions

This document records key architectural decisions (ADRs) made when designing the secure data lake AWS platform. These short ADRs capture the rationale and trade-offs considered.

## ADR-001: Use a multi-account strategy

**Context:** Separating workloads into multiple AWS accounts improves blast radius, cost isolation and security boundaries. The platform requires separate environments for ingestion, analytics and shared services.

**Decision:** Create three AWS accounts: one for ingestion (data ingestion, ETL), one for the data lake and analytics workloads, and one for shared services such as logging, CI/CD and security tooling.

**Consequences:**  
- Accounts can have distinct guardrails (SCPs) and budgets.  
- Cross-account IAM roles are needed for services that interact (e.g., ingestion writing to raw bucket in analytics account).  
- Additional operational complexity for network peering and consolidated billing.

## ADR-002: Adopt infrastructure as code (Terraform)

**Context:** Manual creation of AWS resources is error-prone. Repeatable and auditable infrastructure is needed for compliance and secure CI/CD.

**Decision:** Use Terraform to define all networking, IAM, S3 buckets, logging and other components of the platform. Terraform state is stored in a secure bucket.

**Consequences:**  
- Enables change reviews via pull requests and plan/apply gating.  
- Policy-as-code tools (tfsec, Checkov) can enforce security controls.  
- Requires maintaining modules and versioning.

## ADR-003: IAM patterns for least privilege

**Context:** Data engineers, analysts and services require different levels of access to the data zones. Overly permissive roles increase risk of data exposure or abuse.

**Decision:** Define distinct IAM roles for data engineers (read/write in raw and cleaned zones) and data analysts (read-only on curated zone). Use resource-based policies on S3 buckets and Lake Formation tags to enforce column/row-level controls.

**Consequences:**  
- Analysts cannot access raw or cleaned data.  
- ETL jobs run with roles that can transform data and write to cleaned/curated buckets.  
- Additional complexity to maintain fine-grained permissions and tags.

## ADR-004: Balancing usability versus least privilege

**Context:** Strict least privilege can impede productivity if users cannot quickly access necessary data sets. However, too much access undermines security.

**Decision:** Provide curated datasets in the curated zone with broad read access for analysts, while restricting sensitive fields using Lake Formation tags. For ad-hoc exploration, allow analysts to request temporary elevated access through AWS IAM Identity Center (SSO) with approval.

**Consequences:**  
- Analytics users have frictionless access to approved datasets.  
- Sensitive data remains protected and access is auditable.  
- Requires processes for approving and granting temporary permissions.

## ADR-005: Centralized logging and monitoring

**Context:** Compliance frameworks require centralized audit logs. Each account generates CloudTrail logs, but storing logs within the same account could allow tampering.

**Decision:** Route all CloudTrail and service logs to a dedicated logging bucket in the shared services account. Enable CloudTrail organisation trail and set up CloudWatch alarms for suspicious activities.

**Consequences:**  
- Logs are immutable and separated from workloads.  
- Monitoring and alerting can be managed centrally.  
- Additional cross-account IAM roles and bucket policies needed.
