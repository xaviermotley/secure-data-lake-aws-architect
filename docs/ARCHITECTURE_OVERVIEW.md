# Architecture Overview  

This document provides a high-level overview of the secure, multi account AWS data platform implemented in this repository. The design separates ingestion, analytics, and shared services to enforce least privilege and ease of management. It also divides the data lake into multiple storage zones to control access and implement data lifecycle policies.  

## High‑Level Architecture  

The platform uses three AWS accounts:  

- **Ingestion account** – Receives data via streaming (Amazon Kinesis Data Streams or Amazon MSK) or batch ingestion. Raw data is stored in an Amazon S3 bucket in the raw zone.  

- **Analytics account** – Hosts the data lake and analytics services. Data is replicated from the ingestion account into raw, cleaned, and curated buckets. Glue/Lake Formation or ETL frameworks transform data from raw to curated zones. Analytical tools (e.g., Amazon EMR, Amazon Athena, or Databricks) access curated data through fine‑grained IAM roles and Lake Formation permissions.  

- **Shared services account** – Contains centralized CI/CD pipelines, logging, security tools (GuardDuty, Config), and cross‑account IAM roles. This account centralises CloudTrail and CloudWatch logs from all accounts, enabling unified security monitoring and compliance.  

The following mermaid diagram summarises the high‑level data flows and account boundaries:  

```mermaid
graph TD
  subgraph Ingestion Account
    prod_sources[Producers (Apps, Devices)] --> kinesis[Kinesis/MSK Streams]
    kinesis --> s3_raw_ingest[S3 Raw Zone]
  end
  subgraph Analytics Account
    s3_raw_ingest --> s3_raw[Raw Bucket]
    s3_raw --> glue[Glue/Lake Formation ETL]
    glue --> s3_clean[Cleaned Bucket]
    s3_clean --> s3_curated[Curated Bucket]
    s3_curated --> analytics[Analytics Platform (Athena/EMR/Databricks)]
  end
  subgraph Shared Services Account
    ci_cd[CI/CD & Security Tools] --> {All Accounts}
    logging[Central Logging (CloudTrail/CloudWatch)] --> {All Accounts}
  end
```

The ingestion account writes raw data to an S3 bucket. Cross‑account replication or batch copy brings raw data into the analytics account. ETL jobs in the analytics account read from the raw bucket, perform cleansing and transformation, and write to the cleaned and curated zones. Analysts and data scientists access curated datasets through fine‑grained roles and Lake Formation tags. Centralized CI/CD pipelines deploy and update infrastructure as code across accounts, and centralized logging collects CloudTrail logs to support auditing and detection.  

## Data Lake Zones  

The data lake implements distinct storage zones to handle data through its lifecycle. AWS recommends organising a data lake into separate raw, cleaned, and curated zones ([docs.aws.amazon.com](https://docs.aws.amazon.com/whitepapers/latest/aws-serverless-data-analytics-pipeline/logical-architecture-of-modern-data-lake-centric-analytics-platforms.html#:~:text=layer%20is%20organized%20into%20the,across%20organizations%20use%20the%20data)). The raw zone stores data exactly as ingested, preserving original schemas and formats. The cleaned zone (sometimes called stage or refined) holds data after preliminary quality checks and validation; data can be converted into open formats like Parquet here. The curated zone contains consumption‑ready datasets that are optimised for query performance and analytics. Each zone is implemented as a separate S3 bucket with versioning enabled and lifecycle policies that transition older data to infrequent access or Glacier per compliance needs ([docs.aws.amazon.com](https://docs.aws.amazon.com/prescriptive-guidance/latest/defining-bucket-names-data-lakes/data-layer-definitions.html)).  

Using distinct zones enables enforcement of least privilege (e.g., analysts can only access curated data) and reduces blast radius in case of compromise. It also simplifies cost management by applying different storage classes and retention policies to each zone.  

## Multi‑Account Strategy  

A multi‑account architecture isolates workloads and security contexts. The ingestion account can be granted permissions to ingest data from external producers without exposing the analytics account. The analytics account holds the data lake and analytics services and is tightly controlled. The shared services account contains cross‑account roles, central CI/CD pipelines, and security services such as AWS Config rules, GuardDuty, and IAM Access Analyzer. This separation supports the principle of least privilege, simpler billing, and easier compliance. Cross‑account IAM roles and resource policies control access between accounts.  

## Networking and IAM  

Each account uses a dedicated VPC with private and public subnets, NAT gateways, and security groups restricting inbound/outbound traffic. VPC endpoints for S3 and other AWS services allow private connectivity from ETL jobs and analytics services. IAM roles are defined for data engineers, analysts, and services. For example, ingestion roles can write to the raw bucket but cannot read; ETL roles can read raw data and write to cleaned/curated buckets; analytics roles can query curated data using Athena or EMR but cannot modify raw data. Fine‑grained permissions in Lake Formation further restrict row‑ or column‑level access where needed.  

## Logging and Monitoring  

All accounts send CloudTrail logs to a central S3 bucket in the shared services account. CloudWatch Logs collect application logs and glue job logs. GuardDuty, Security Hub, and AWS Config provide continuous monitoring, vulnerability detection, and compliance checks. Metrics and alarms can be configured to detect abnormal ingestion patterns or changes to IAM policies.  

## Conclusion  

This architecture provides a secure foundation for an AWS data lake that integrates ingestion pipelines, multi‑zone storage, analytics platforms, and secure CI/CD. By leveraging infrastructure as code, strong IAM roles, and centralized logging, the platform meets compliance requirements (NIST 800‑53 / CSF) while remaining flexible for analytics workloads.
