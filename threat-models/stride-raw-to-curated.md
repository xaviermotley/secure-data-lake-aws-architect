# STRIDE Threat Model – Raw to Curated Zone

This document analyzes threats for the data transformation pipeline that moves data from the raw zone to the curated zone. Data is cleaned, transformed, and enriched by ETL jobs (e.g., AWS Glue, EMR) and stored into curated S3 buckets for consumption. The flow can be cross-account (ingestion account to analytics account) according to our multi-account architecture.

## Overview

Data from the raw zone is processed by ETL jobs in the analytics account. These jobs read from the raw zone, apply transformations, and write to the curated zone. The curated zone contains structured, cleaned, and possibly aggregated datasets used by analytics tools. Key security considerations include cross-account access, least privilege, encryption, and auditability.

### Threat Mapping

| Threat | Control | AWS Implementation |
| --- | --- | --- |
| **Spoofing** – Unauthorized ETL jobs or users impersonate legitimate pipelines. | Use IAM roles dedicated to ETL jobs; require cross-account access via resource-based policies; enforce mutual TLS for service endpoints. | Create cross-account roles with specific `AssumeRole` trust policies for Glue/EMR jobs; use Lake Formation principals to restrict who can read/write; enforce AWS STS conditions. |
| **Tampering** – Data is tampered during processing or transformation. | Use checksums and cryptographic signatures to validate data; version data; restrict write access to curated zone; encrypt intermediate data. | Enable S3 object versioning and bucket policies for curated buckets; compute and store checksums/hashes for data; use Glue job bookmarks and data quality checks; store intermediate results in encrypted S3 with SSE-KMS. |
| **Repudiation** – Actors deny performing transformations. | Maintain full audit trails for ETL jobs; record data lineage; enforce signed API calls. | Enable CloudTrail logging for Glue/EMR; use AWS Lake Formation data lineage features; send job logs to CloudWatch and central logging; require signed requests. |
| **Information Disclosure** – Sensitive data is leaked during transformation or cross-account transfer. | Encrypt data at rest and in transit; implement fine-grained access controls; mask PII during transformation. | Use KMS encryption for S3 buckets and Glue job bookmarks; use Lake Formation LF-Tags to define access policies; restrict cross-account role policies to only required buckets; implement data masking/transformation logic in ETL jobs (e.g., AWS Glue DataBrew). |
| **Denial of Service** – ETL infrastructure overwhelmed. | Use autoscaling clusters and job concurrency limits; monitor job metrics; isolate workloads by account. | Configure Glue/EMR job capacity and concurrency quotas; use Step Functions or MWAA to orchestrate jobs with retries; set CloudWatch alarms on job failures and resource utilization; separate ingestion and analytics accounts to limit blast radius. |
| **Elevation of Privilege** – ETL job obtains unauthorized permissions to other resources. | Follow least-privilege principle; separate roles for reading raw and writing curated; use IAM conditions. | Create distinct IAM roles for reading raw S3 buckets and writing curated; restrict these roles with `Resource` and `Condition` clauses; use service control policies to block privilege escalation; regularly audit with AWS IAM Access Analyzer and AWS Config rules. |
