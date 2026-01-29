# StartTech Infrastructure

Infrastructure as Code (IaC) repository for StartTech's full-stack application using Terraform and AWS.

## Architecture Overview

- **Frontend**: React app on S3 + CloudFront CDN
- **Backend**: Golang API on EC2 Auto Scaling Group behind ALB
- **Cache**: ElastiCache Redis cluster
- **Database**: MongoDB Atlas
- **Monitoring**: CloudWatch Logs and Alarms

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.13.3
- GitHub CLI (gh) for secrets management

## Repository Structure

```
starttech-infra/
├── .github/workflows/
│   └── infrastructure-deploy.yml
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   └── modules/
│       ├── networking/
│       ├── compute/
│       ├── storage/
│       └── monitoring/
├── scripts/
│   └── deploy-infrastructure.sh
└── monitoring/
    ├── cloudwatch-dashboard.json
    ├── alarm-definitions.json
    └── log-insights-queries.txt
```

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/Ife-Olaitan/starttech-infra.git
cd starttech-infra
```

### 2. Configure variables

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Deploy infrastructure

**Option A: Using CI/CD (recommended)**

Push to `main` branch to trigger automatic deployment.

**Option B: Manual deployment**

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `TF_VAR_NAME` | Project name prefix |
| `TF_VAR_AWS_REGION` | AWS region (eu-west-2) |
| `TF_VAR_VPC_CIDR` | VPC CIDR block |
| `TF_VAR_PUBLIC_SUBNET_CIDRS` | Public subnet CIDRs (JSON array) |
| `TF_VAR_PRIVATE_SUBNET_CIDRS` | Private subnet CIDRs (JSON array) |
| `TF_VAR_INSTANCE_TYPE` | EC2 instance type |
| `TF_VAR_DOCKERHUB_IMAGE` | Docker Hub image name |
| `TF_VAR_MONGO_URI` | MongoDB connection string |
| `TF_VAR_JWT_SECRET` | JWT secret key |
| `GH_PAT` | GitHub PAT for setting secrets in app repo |

## Outputs

After deployment, these values are available:

- `cloudfront_distribution_id` - For cache invalidation
- `cloudfront_domain_name` - Frontend URL
- `alb_dns_name` - Backend API URL
- `asg_name` - For triggering deployments

## Destroying Infrastructure

```bash
cd terraform
terraform destroy
```

## Related Repository

- [starttech-application](https://github.com/Ife-Olaitan/starttech-application) - Application code and CI/CD