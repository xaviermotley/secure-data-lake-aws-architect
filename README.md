# secure-data-lake-aws-architect  

**Positioning statement**  
Designed and implemented a reference architecture and threat model for a secure AWS-based data platform integrating commercial analytics components and secure CI/CD.  

## Overview  
This repository provides a reference implementation of a secure, multi account AWS data platform. The goal is to demonstrate how to ingest data, store it in a multi zone data lake, transform it using ETL jobs, and expose it to analytics tools while maintaining a high level of security and compliance. The project includes infrastructure‑as‑code (Terraform), threat models based on STRIDE, a secure CI/CD pipeline, and mappings to NIST 800 ‑53 and the NIST Cybersecurity Framework.  

The architecture separates workloads into three AWS accounts: ingestion, analytics, and shared services. Data is organized into raw, cleaned and curated zones as recommended by AWS ([docs.aws.amazon.com](https://docs.aws.amazon.com/whitepapers/latest/aws-serverless-data-analytics-pipeline/logical-architecture-of-modern-data-lake-centric-analytics-platforms.html#:~:text=layer%20is%20organized%20into%20the,across%20organizations%20use%20the%20data)). Lifecycle policies and versioning are applied to each zone and data is promoted from raw to curated via ETL. This separation enforces least privilege, reduces blast radius and simplifies retention policies ([docs.aws.amazon.com](https://docs.aws.amazon.com/prescriptive-guidance/latest/defining-bucket-names-data-lakes/data-layer-definitions.html)).  

## Repository structure  
- **`iac/`** – Terraform modules that deploy the core platform: VPCs, subnets, IAM roles and policies, S3 buckets for raw/cleaned/curated zones, Kinesis/MSK ingestion, Glue/Lake Formation, and centralized logging/CloudTrail.  
- **`threat-models/`** – System data flow diagram and STRIDE-based threat models for ingestion→raw, raw→curated and analytics access flows. Each model maps threats to controls and specific AWS implementations.  
- **`ci-cd/`** – GitHub Actions workflow and documents for secure CI/CD. The workflow performs Terraform plan/apply, static analysis (Checkov/tfsec), OPA policy checks, and manages secrets. The `SECURITY_DESIGN.md` file describes how pull requests are reviewed, how environments are promoted (dev→stage→prod), and how security checks gate merges.  
- **`controls/`** – Mapping of NIST 800 ‑53/CSF control families to specific AWS services and configurations used in this architecture.  
- **`docs/`** – Architectural overview, diagrams and architectural decision records (ADRs) explaining design choices.  

## Prerequisites  
To deploy and experiment with this platform you will need:  
- An AWS Organization with at least three accounts (ingestion, analytics and shared‑services).  
- AWS CLI installed and configured with profiles for each account.  
- Terraform CLI (≥ v1.5) installed locally.  
- Optional: GitHub repository with Actions enabled to run the provided CI/CD workflow.  

## Quick start  
1. **Clone this repository**  
   ```bash  
   git clone https://github.com/<your-user>/secure-data-lake-aws-architect.git  
   cd secure-data-lake-aws-architect  
   ```  
2. **Configure AWS profiles**  
   Create or update your `~/.aws/config` and `~/.aws/credentials` files with profiles for the ingestion, analytics and shared‑services accounts. Export `TF_VAR_ingestion_profile`, `TF_VAR_analytics_profile` and `TF_VAR_shared_services_profile` environment variables pointing to those profiles so Terraform can assume the right roles.  
3. **Deploy the infrastructure**  
   ```bash  
   cd iac  
   terraform init      # download providers and modules  
   terraform plan      # view the resources that will be created  
   terraform apply     # deploy the VPCs, buckets, roles and logging (requires approval)  
   ```  
   By default this will provision: VPCs/subnets, S3 buckets with encryption and versioning, IAM roles for ingestion, ETL and analytics, centralized CloudTrail logging, and optional Kinesis stream for ingestion.  
4. **Run ETL/analytics**  
   - After deployment, data producers can write to the ingestion Kinesis stream or directly upload files to the ingestion account’s raw bucket.  
   - Use AWS Glue jobs or Lake Formation workflows to transform data from raw to cleaned and curated zones.  
   - Query curated data using Amazon Athena, Amazon EMR, or Databricks with roles defined in the `iac` module.  
5. **CI/CD pipeline**  
   Push changes to the `iac/` directory or open a pull request. The GitHub Actions workflow (`ci-cd/main.yml`) will automatically run `terraform init` and `terraform plan`, perform security scans with Checkov, tfsec and OPA policies, and require a manual approval before applying changes to production. See `ci-cd/SECURITY_DESIGN.md` for details.  

## Threat modeling  
The `threat-models/` folder contains a system data flow diagram (DFD) and three STRIDE-based threat models:  
- `system-dfd.md` – Mermaid diagram that shows producers streaming into the ingestion account, replication into the analytics account, ETL jobs transforming data and central services.  
- `stride-ingestion-to-raw.md` – Analysis of threats when ingesting data from external producers into the raw zone.  
- `stride-raw-to-curated.md` – Threats and controls for the ETL process that moves data from raw to curated zones.  
- `stride-analytics-access.md` – Threat model for how analysts and data scientists access curated datasets.  

Each threat model includes a table mapping threats (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege) to controls and AWS implementations such as IAM conditions, KMS policies, Lake Formation tags and CloudWatch alarms.  

## Controls mapping  
The `controls/control-mapping-nist-800-53.md` file provides a concise mapping of selected NIST 800 ‑53 control families (AC, AU, CM, SC, SI) to specific AWS services and configurations used in this design. Use this to demonstrate compliance alignment when working in regulated environments.  

## Documentation  
- `docs/ARCHITECTURE_OVERVIEW.md` – A comprehensive 2‑3 page overview that explains the high‑level architecture, multi‑account pattern, data lake zones, networking and IAM design, and logging/monitoring approach. Includes a Mermaid diagram summarizing data flows.  
- `docs/DECISIONS.md` – Architectural decision records capturing why a multi‑account strategy was chosen, how IAM patterns balance usability vs. least privilege, and rationale for key design choices.  

## Contributing  
If you wish to extend this reference architecture (e.g., add support for additional data sources, integrate other analytics engines, or refine security controls), please fork the repository and open a pull request. Ensure that any infrastructure changes include corresponding updates to the threat models, control mappings and documentation. Before merging, the CI/CD pipeline must pass all security checks and require approval.  

---  

This README provides a starting point for using and understanding the secure-data-lake-aws-architect project. For more details, explore the individual directories and documents. Feel free to adapt the modules and patterns here to suit your own data platform needs.
