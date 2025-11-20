# secure-data-lake-aws-architect  
**Positioning statement**  
Designed and implemented a reference architecture and threat model for a secure AWS‑based data platform integrating commercial analytics components and secure CI/CD.  

## Overview  
This repository provides a reference implementation of a secure, multi account AWS data platform. The goal is to demonstrate how to ingest data, store it in a multi zone data lake, transform it using ETL jobs, and expose it to analytics tools while maintaining a high level of security and compliance. The project includes infrastructure‑as‑code (Terraform), threat models based on STRIDE, a secure CI/CD pipeline, and mappings to NIST 800 ‑53 and the NIST Cybersecurity Framework.  
The architecture separates workloads into three AWS accounts: ingestion, analytics, and shared services. Data is organized into raw, cleaned and curated zones as recommended by AWS ([docs.aws.amazon.com](https://docs.aws.amazon.com/whitepapers/latest/aws-serverless-data-analytics-pipeline/logical-architecture-of-modern-data-lake-centric-analytics-platforms.html#:~:text=layer%20is%20organized%20into%20the,across%20organizations%20use%20the%20data), [docs.aws.amazon.com](https://docs.aws.amazon.com/prescriptive-guidance/latest/defining-bucket-names-data-lakes/data-layer-definitions.html)). Lifecycle policies and versioning are applied to each zone and data is promoted from raw to curated via ETL. This separation enforces least privilege, reduces blast radius and simplifies retention policies.  

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
   terraform plan -out=plan.tfplan  
   terraform apply plan.tfplan  
   ```  
   The Terraform code will create VPCs, subnets, S3 buckets, IAM roles, Kinesis/MSK streams and other resources across the three accounts.  
4. **Run ETL and analytics jobs**  
   - **Ingestion account**: stream data to Kinesis or MSK and land it in the raw zone.  
   - **Analytics account**: use Glue or Lake Formation to transform raw data to cleaned and curated zones.  
   - Use Databricks/EMR or Athena to query curated data.  
5. **Run the CI/CD pipeline**  
   - Push changes to the `iac` folder and open a pull request.  
   - GitHub Actions will run Terraform plan and static analysis (Checkov, tfsec, OPA).  
   - After review and approvals, the pipeline can apply changes to dev/stage/prod environments.  

## Securing your data lake on AWS  
Building a secure data lake is not only about ingesting and storing data; it involves protecting sensitive information, complying with regulations and ensuring that only authorized users and services can access the right data at the right time. The following principles underpin this project:  
- **Multi‑account isolation**: separate ingestion, analytics and shared services into distinct AWS accounts to contain blast radius and reduce privileges. Cross‑account roles and resource policies are used to grant least‑privileged access between accounts.  
- **Zone separation**: organize data into raw, cleaned and curated S3 buckets. Raw data may contain PII or sensitive information and is tightly controlled; cleaned data is processed; curated data is ready for consumption. This separation allows you to apply different IAM policies, KMS keys and lifecycle rules to each zone ([docs.aws.amazon.com](https://docs.aws.amazon.com/whitepapers/latest/aws-serverless-data-analytics-pipeline/logical-architecture-of-modern-data-lake-centric-analytics-platforms.html#:~:text=layer%20is%20organized%20into%20the,across%20organizations%20use%20the%20data), [docs.aws.amazon.com](https://docs.aws.amazon.com/prescriptive-guidance/latest/defining-bucket-names-data-lakes/data-layer-definitions.html)).  
- **Encryption at rest and in transit**: all buckets use SSE‑KMS encryption with customer‑managed KMS keys. IAM policies enforce that only TLS‑encrypted requests are allowed. Data flowing via Kinesis/MSK and Glue jobs is also encrypted.  
- **Least‑privilege IAM**: define IAM roles for ingestion services, ETL jobs, and analytics users. Each role grants only the permissions needed for its task (e.g., read from raw, write to cleaned). Deny statements prevent access to restricted zones.  
- **Fine‑grained access control with Lake Formation**: use Lake Formation and AWS Glue Data Catalog to implement table‑, column‑ or row‑level permissions. LF‑Tags and resource links restrict data sets to authorized analysts.  
- **Network segmentation**: deploy VPCs with private subnets for ingestion pipelines and analytics clusters. Use VPC endpoints (Gateway and Interface) for S3, Kinesis, Glue and Secrets Manager to keep traffic on the AWS backbone. Security groups and NACLs restrict ingress/egress.  
- **Logging and monitoring**: enable CloudTrail, AWS Config and S3 access logs in a shared services account. Use GuardDuty, Macie and Inspector for threat detection. Centralize logs in CloudWatch and forward to SIEM for alerting.  
- **Secrets management**: store credentials (database passwords, API keys) in AWS Secrets Manager or SSM Parameter Store. The CI/CD pipeline retrieves secrets at runtime rather than hardcoding them.  
- **Automated compliance checks**: integrate tools like Checkov, tfsec and OPA (Conftest) in the CI/CD pipeline to scan Terraform code for misconfigurations and enforce policies such as mandatory encryption, bucket versioning and least‑privilege.  
- **Lifecycle and retention policies**: apply S3 lifecycle rules to transition data to infrequent access and Glacier after a defined period. Enable versioning and MFA delete on buckets to protect against accidental or malicious deletion.  

### Step‑by‑step hardening  
The following steps describe how the Terraform code and configuration in this repo implement the above principles:  
1. **Create and encrypt S3 buckets**: Each zone bucket (`raw`, `cleaned`, `curated`) is created with versioning enabled, lifecycle policies for archival, and SSE‑KMS encryption. Bucket policies enforce HTTPS, restrict public access and require specific IAM principals.  
2. **Provision KMS keys**: Customer‑managed keys are provisioned in each account. Key policies grant access only to relevant IAM roles (ingestion services, ETL jobs, analytics roles) and to the security team. Rotation is enabled.  
3. **Define IAM roles and policies**: For ingestion services (Kinesis/MSK), ETL roles (Glue/EMR) and analytics users (e.g., Athena/Databricks). Policies grant minimal S3 actions on specific prefixes (e.g., `s3:GetObject` on `raw/*` for ETL) and restrict cross‑account trust relationships.  
4. **Set up Lake Formation**: Register the data lake in Lake Formation, define LF‑Tags for domains (e.g., PII, Finance) and assign them to tables. Grant data access to IAM roles via LF‑Tag policies.  
5. **Deploy VPCs and endpoints**: Create VPCs with private subnets in each account. Add VPC endpoints for S3, Kinesis, Glue, Secrets Manager, ECR to ensure that traffic stays within AWS.  
6. **Enable logging and detection**: Set up CloudTrail organization trail, S3 access logs, and AWS Config rules that ensure encryption and logging are enabled. Configure GuardDuty, Macie and Inspector in the shared services account and integrate findings into central logging.  
7. **Configure CI/CD security gates**: The GitHub Actions pipeline runs `terraform plan` and static analysis to catch misconfigurations. Plans require manual approval before apply. OPA policies enforce secure patterns (e.g., no public S3 buckets). Secrets are injected from the AWS credentials store via environment variables.  

## Threat modeling & controls mapping  
Detailed threat models for each major flow are provided in the `threat-models/` folder. These documents apply the STRIDE methodology to identify spoofing, tampering, repudiation, information disclosure, denial of service and elevation‑of‑privilege threats. For each threat, appropriate controls are suggested and mapped to AWS implementations such as IAM conditions, KMS policies, Lake Formation tags and CloudWatch alarms. The `controls/control-mapping-nist-800-53.md` file maps these controls to NIST 800‑53/CSF families.  

## Documentation  
- **`docs/ARCHITECTURE_OVERVIEW.md`** – a multi‑page overview with diagrams describing the platform architecture, account separation, data zones, network design, and security mechanisms.  
- **`docs/DECISIONS.md`** – architectural decision records (ADRs) capturing why multi‑account segregation, specific IAM patterns and other trade‑offs were chosen.  

## Contributing  
Contributions are welcome! Please open issues or pull requests if you have suggestions for improving the architecture, adding additional threat models or extending the CI/CD pipeline. Ensure that any code changes pass the security checks in the pipeline before requesting a review.
