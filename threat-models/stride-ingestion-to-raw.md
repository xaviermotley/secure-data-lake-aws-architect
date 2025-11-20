# STRIDE Threat Model – Ingestion to Raw Zone

This document analyzes threats for the ingestion pipeline delivering data to the raw zone in the AWS data lake architecture. We use the STRIDE framework to identify potential threats and align them with controls and concrete AWS implementations.

## Overview

Ingestion flows from external producers or internal event streams (Kinesis or MSK) into the ingestion account. Data is landed into the raw S3 bucket via ETL or streaming ingestion. The raw zone is the immutable landing zone for all incoming data in its original format. Key security considerations include identity verification, encryption, audit logging, and safe network boundaries.

### Threat Mapping

| Threat | Control | AWS Implementation |
| --- | --- | --- |
| **Spoofing** – Unauthenticated actors impersonate producers or services to inject data. | Use mutual TLS and AWS IAM authentication for producers; require signed AWS SigV4 requests; enforce least-privilege IAM roles. | Create IAM roles with limited permissions for ingestion services and require producers to assume roles with MFA; use Amazon MSK with IAM/SASL authentication; for REST endpoints use API Gateway/ALB with mutual TLS and ACM certificates. |
| **Tampering** – Data is modified in transit or at rest. | Encrypt data in transit and at rest; enable S3 versioning to track changes; restrict write access. | Use TLS connections for Kinesis/MSK/ETL; enable server-side encryption (SSE-KMS) on the raw S3 bucket; set bucket policies to permit only ingestion roles to write; enable versioning and object lock on raw bucket. |
| **Repudiation** – Actors deny having ingested or modified data. | Maintain immutable logs of all interactions; enforce signed requests and unique identities. | Enable AWS CloudTrail for all accounts and integrate with centralized logging; enable S3 server access logging; require producers to use IAM roles so requests are traceable. |
| **Information Disclosure** – Sensitive data is exposed during ingestion. | Encrypt channels and storage; restrict access to raw zone; use network isolation. | Use VPC endpoints for S3/Kinesis/MSK to keep traffic within AWS; apply S3 bucket policies that limit `GetObject` to only ETL service roles; enable KMS key policies restricting decrypt operations; mask PII in ingestion where possible. |
| **Denial of Service** – Attackers overwhelm ingestion endpoints or S3. | Rate‑limit ingestion, scale ingestion services, and monitor for anomalous spikes. | Use Amazon Kinesis enhanced fan‑out or MSK autoscaling; configure AWS WAF on API endpoints with rate limiting; set S3 bucket request metrics and alarms via CloudWatch to detect unusual throughput; apply quotas on MSK partitions. |
| **Elevation of Privilege** – Compromised ingestion role obtains elevated permissions. | Enforce least-privilege roles; separate duties; enforce conditions on role assumption. | Define IAM policies granting only necessary S3 PutObject and Kinesis permissions; include `aws:SourceVpc` and `aws:SourceArn` conditions in bucket policies; implement service control policies (SCPs) to block privilege escalation; monitor IAM with AWS Config rules and Security Hub. |

This table demonstrates how each STRIDE category is addressed using AWS services and security features.
