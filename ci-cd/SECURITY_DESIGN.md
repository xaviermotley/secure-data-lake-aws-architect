# SECURITY_DESIGN.md  
## Secure CI/CD Design  
This document outlines the secure continuous integration and deployment (CI/CD) practices for the **secure-data-lake-aws-architect** project. The pipeline is built using GitHub Actions and Terraform to provision infrastructure in AWS. Key goals are to ensure that infrastructure changes are peer reviewed, tested, scanned against policies, and promoted through environments with security gates.  

### Pipeline Overview  
- **Source Control**: All infrastructure code lives in the `iac/` directory and is version‭controlled in Git. Each change must go through a pull request (PR). Branch protection rules enforce code reviews, signed commits and successful checks before merging into `main`.  
- **Terraform Plan & Apply**: The pipeline runs `terraform init` and `terraform plan` to generate an execution plan. Plans are stored as artifacts and can be manually reviewed. The apply step only runs on pushes to `main` and targets the appropriate environment.  
- **Policy as Code**: During PRs, static analysis tools such as [Checkov](https://www.bridgecrew.io/) and [tfsec](https://aquasecurity.github.io/tfsec/) run against the Terraform code. Additionally, [Conftest](https://www.conftest.dev/) enforces OPA policies to ensure compliance with NIST 800‭53 controls.  
- **Secrets Management**: Secrets (e.g., AWS credentials, database passwords) are never stored in code. The pipeline uses GitHub encrypted secrets to retrieve temporary AWS credentials via IAM roles that assume privilege in the corresponding AWS account. Sensitive parameters for services (for example, connection strings) are stored in AWS Systems Manager Parameter Store or Secrets Manager.  
- **Artifact Integrity**: Terraform state is stored remotely in an encrypted S3 bucket with DynamoDB locking to prevent concurrent writes. The state bucket and DynamoDB table reside in the shared services account, with versioning and server‭side encryption enabled.  

### Promotion Workflow  
1. **Development**: Developers open a feature branch and raise a pull request. Automated checks run `terraform plan` against the `dev` workspace. Checkov, tfsec and OPA policies must pass. At least one senior engineer reviews the changes. Once approved and merged, the apply step deploys to the development account.  
2. **Staging**: A separate `stage` environment mirrors production. Changes are promoted by tagging a release or merging to a `stage` branch. The pipeline runs the same checks and applies to the staging account. Data sanitization ensures that test data does not contain production PII.  
3. **Production**: Deployment to the production account is gated by environment approvals in GitHub. Only designated approvers (e.g., security lead) can approve the workflow. After approval, the pipeline runs `terraform apply` in the `prod` workspace. Monitoring and alerting are enabled to watch for drift, failures and suspicious activity.  

### Security Gates  
- **Static Scanning**: Checkov and tfsec rules enforce encryption, least‭privilege IAM, logging and other best practices. Pull requests fail if high or critical issues are found.  
- **OPA Policies**: Conftest runs custom OPA policies aligned with the threat model and control mappings. Examples include prohibiting public S3 buckets, requiring KMS encryption keys with rotation, and ensuring CloudTrail is enabled.  
- **Manual Approvals**: Deployment to staging and production uses GitHub Environments with required reviewers. Approvers ensure there is a corresponding change request or ticket, assess risk and verify that security scans are green.  
- **Audit Logging**: All pipeline actions are logged in GitHub Actions and CloudTrail (for AWS API calls). Logs are shipped to the shared services account for centralized analysis.  

This security design ensures that infrastructure changes are transparent, auditable and comply with the security objectives of the platform. 
