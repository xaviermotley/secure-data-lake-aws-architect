# secure-data-lake-aws-architect  

Designed and implemented a reference architecture and threat model for a secure AWS ‑based data platform integrating commercial analytics components and secure CI/CD.  

## Overview  

This project is a demonstration of a multi-account AWS data platform with a focus on security, compliance and threat modeling. The architecture consists of ingestion, analytics and shared services accounts, with IaC (Terraform/CDK) modules for networking, IAM, S3 data zones, centralised logging, and CI/CD pipelines. It also includes threat models using STRIDE, controls mapped to NIST 800 ‑53 and the NIST Cybersecurity Framework, and architectural decision records.  

**Repository structure**  

- `iac/` – Terraform modules or CDK stacks implementing the platform (VPCs, subnets, IAM roles, S3 buckets and policies, central logging and CloudTrail).  
- `threat-models/` – system DFD and STRIDE-based threat models for ingestion → raw, raw → curated and analytics access flows with threat→control→AWS implementation tables.  
- `ci-cd/` – secure CI/CD pipelines (GitHub Actions) for terraform plan/apply, policy-as-code scanning, secrets management, and promotion workflows. Includes `SECURITY_DESIGN.md` describing change review, environment promotion and gating security checks.  
- `controls/` – mapping of NIST 800 ‑53/CSF control families to specific AWS configurations used in this architecture.  
- `docs/` – architectural overview and decision records.  

The storage layer of this platform is organised into zones that map to raw, cleaned and curated data layers as recommended by AWS ([docs.aws.amazon.com](https://docs.aws.amazon.com/whitepapers/latest/aws-serverless-data-analytics-pipeline/logical-architecture-of-modern-data-lake-centric-analytics-platforms.html#:~:text=layer%20is%20organized%20into%20the,across%20organizations%20use%20the%20data)). Data enters the raw zone in its original format from the ingestion layer and moves to cleaned and curated zones after validation and transformation ([docs.aws.amazon.com](https://docs.aws.amazon.com/whitepapers/latest/aws-serverless-data-analytics-pipeline/logical-architecture-of-modern-data-lake-centric-analytics-platforms.html#:~:text=layer%20is%20organized%20into%20the,across%20organizations%20use%20the%20data)). Following AWS prescriptive guidance, additional staging or analytics layers can be added depending on sensitivity and lifecycle requirements ([docs.aws.amazon.com](https://docs.aws.amazon.com/prescriptive-guidance/latest/defining-bucket-names-data-lakes/data-layer-definitions.html)).  

## Positioning statement  

“Designed and implemented a reference architecture and threat model for a secure AWS ‑based data platform integrating commercial analytics components and secure CI/CD.” 
