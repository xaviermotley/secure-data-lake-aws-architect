# Control Mapping to NIST 800-53  
This document maps key NIST 800‭53 control families to the AWS configurations implemented in the secure data lake reference architecture. The intent is to demonstrate how the design addresses federal security requirements.  

| NIST family | Control focus (keywords) | AWS implementation (examples) |
|---|---|---|
| **AC – Access Control** | identity & access management; least privilege; segregation of duties | Use AWS IAM roles and policies to grant least‭privilege access; S3 bucket policies for raw, curated and restricted zones; Lake Formation tags for fine‑grained data permissions; separate ingestion, analytics and shared accounts |
| **AU – Audit and Accountability** | logging; monitoring; traceability | Enable CloudTrail in all accounts and send logs to central logging bucket; enable S3 access logging; configure CloudWatch Logs and alarms; maintain audit trails for CI/CD actions |
| **CM – Configuration Management** | baseline configuration; change control; IaC | Use Terraform for infrastructure as code with version control; apply GitHub branch protections; run policy‑as‑code scanning (Checkov, tfsec, OPA) on every commit; use AWS Config rules to detect drift and enforce encryption |
| **SC – System and Communications Protection** | network security; encryption; boundary defense | Deploy resources within VPCs with private subnets; restrict traffic via security groups and NACLs; enforce TLS encryption in transit; encrypt data at rest with KMS‑managed keys; enable VPC flow logs |
| **SI – System and Information Integrity** | vulnerability management; threat detection; data protection | Use AWS GuardDuty for threat detection; AWS Macie for sensitive data discovery; AWS Inspector for vulnerability scanning; implement S3 object versioning and lifecycle policies; enforce automatic key rotation |  

This mapping is not exhaustive but highlights how the proposed architecture aligns with major NIST 800”53 control families for a secure data analytics platform. 
