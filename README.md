# AWS Incident Response Runbook

## Overview
This project deploys a complete Incident Response (IR) infrastructure on AWS using Terraform. It simulates real-world security incidents, detects threats automatically, and provides a structured runbook for containment, eradication, and recovery.

## Architecture
- **SNS Alerts** — Immediate email notification when incidents are detected
- **Evidence Bucket** — Encrypted, versioned S3 bucket for storing incident evidence
- **KMS Key** — Evidence encrypted at rest with customer managed key
- **CloudWatch Logs** — 365 day retention for full incident timeline
- **IR Responder Role** — Read only access during investigations
- **Alarms** — Detects unauthorized API calls, logins without MFA, and root account usage

## Security Features
- Evidence bucket versioning — preserves all evidence, nothing can be deleted
- KMS encryption on all evidence
- Public access completely blocked on evidence bucket
- 365 day log retention for legal and compliance requirements
- Read only IR role — investigators can't accidentally modify evidence
- Real time alerting on three critical threat scenarios

## Incident Scenarios Covered
1. Unauthorized API calls
2. Console login without MFA
3. Root account usage

## Tools Used
- Terraform v1.15.5
- AWS CLI
- AWS Services: SNS, S3, KMS, CloudWatch, IAM

## How to Deploy
1. Clone this repository
2. Configure AWS credentials: `aws configure`
3. Update your email in `main.tf` for SNS alerts
4. Initialize Terraform: `terraform init`
5. Preview changes: `terraform plan`
6. Deploy: `terraform apply`
7. Confirm your SNS email subscription

## What I Learned
This project taught me how to build a real incident response infrastructure on AWS. I learned how to preserve digital evidence, set up detection for the most common attack scenarios, and create a read only investigation role — directly applicable to SOC analyst and IR engineer roles.

## Author
Michael Olu-Ajayi — Aspiring Cloud Security Engineer