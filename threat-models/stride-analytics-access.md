# STRIDE Threat Model – Analytics Access

This document analyzes threats related to analytics users and services accessing the curated zone of the data lake. This includes interactive query services (e.g., Athena, Redshift Spectrum, Databricks) and dashboards used by data scientists and analysts.

## Overview

Analytics users operate in the analytics account. They read curated datasets from S3 or data catalogs using tools like AWS Lake Formation, Glue Data Catalog, Amazon Athena, Amazon Redshift, EMR, or third-party analytics platforms. Access is granted through IAM roles and Lake Formation policies. Security priorities include enforcing least privilege, fine-grained access control, encryption, and monitoring user activity.

### Threat Mapping

| Threat | Control | AWS Implementation |
| --- | --- | --- |
| **Spoofing** – Unauthorized users masquerade as legitimate analysts or services. | Enforce MFA for human users; use SSO/SAML integration; issue short‑lived credentials via STS; implement AWS IAM Identity Center. | Require MFA for AWS Console and CLI; configure IAM Identity Center integrated with corporate IdP; create per‑user IAM roles with limited privileges; use Lake Formation to grant permissions to specific principals. |
| **Tampering** – Data in the curated zone or analytics results are altered. | Use immutable storage for curated data; restrict write access; track data lineage and use row-level security; sign query results. | Enable S3 versioning and object lock on curated buckets; restrict `PutObject` to specific service roles; use Lake Formation LF-tags for row and column-level governance; sign results via custom application logic. |
| **Repudiation** – Users deny having accessed or queried data. | Maintain comprehensive audit logs of data access and queries; enable user activity logging. | Enable CloudTrail data event logging for S3 and Lake Formation; enable Athena and Redshift audit logs to CloudWatch; send logs to a centralized logging account for retention and analysis; maintain Lake Formation query history. |
| **Information Disclosure** – Unauthorized disclosure of sensitive data through analytics tools. | Implement fine-grained access control with column/row-level permissions; classify and tag sensitive data; encrypt query results. | Use Lake Formation LF-tags and data permissions to control column-level access; integrate Amazon Macie for data classification; apply KMS encryption on S3 and Athena query result buckets; restrict data sharing via cross-account Resource Access Manager. |
| **Denial of Service** – Excessive queries or resource consumption degrade analytics services. | Apply query quotas and resource limits; use workload management; monitor usage patterns. | Configure Athena workgroups with query limits and budgets; use Redshift concurrency scaling and workload management queues; set CloudWatch alarms on query runtime and failures; restrict access to heavy compute clusters; implement service quotas. |
| **Elevation of Privilege** – Analysts gain access to more data than intended or assume higher-privilege roles. | Separate duties through role-based access control; enforce least privilege; restrict `iam:PassRole` permissions. | Define separate IAM roles for analysts, data scientists, and admins; use Lake Formation to grant dataset-specific permissions; deny `iam:PassRole` on higher-privilege roles via service control policies; use AWS Config rules and IAM Access Analyzer to detect overly broad permissions; implement permission boundaries. |
