# 🏗️ Intelligent Data Archiving Platform

> **Cost Optimization** — Automatically move cold data (logs, invoices) to cheaper AWS storage tiers and save thousands on cloud bills.

## 🏛️ Architecture

```
┌──────────────┐     ┌──────────────┐     ┌───────────────────────────┐
│  Spring Boot │────▶│  AWS Lambda  │────▶│  PostgreSQL (RDS)         │
│  REST API    │     │  (Python)    │     │  ─ application_logs       │
│  :8081       │     │              │     │  ─ invoices               │
└──────────────┘     └──────┬───────┘     └───────────────────────────┘
                            │
                            ▼
                   ┌────────────────┐
                   │  Amazon S3     │
                   │  ┌───────────┐ │
                   │  │ Standard  │ │ ── Day 0
                   │  ├───────────┤ │
                   │  │ Intel.    │ │ ── Day 30
                   │  │ Tiering   │ │
                   │  ├───────────┤ │
                   │  │ Glacier   │ │ ── Day 90
                   │  ├───────────┤ │
                   │  │ Deep      │ │ ── Day 365
                   │  │ Archive   │ │
                   │  └───────────┘ │
                   └────────────────┘
```

## 🌐 AWS Services Used (Real)

| Service | Purpose | Free Tier |
|---------|---------|-----------|
| **S3** | Archived data storage with lifecycle policies | 5 GB Standard |
| **Lambda** | Cold data archiver (Python 3.12) | 1M requests/month |
| **RDS** | PostgreSQL 15 source database | 750h db.t3.micro/month |
| **EventBridge** | Daily archival trigger (cron) | Free |
| **CloudWatch** | Lambda logs & monitoring | 5 GB logs/month |
| **VPC** | Network isolation for RDS + Lambda | Free |
| **IAM** | Least-privilege roles | Free |

## 📁 Project Structure

```
data-archival-platform/
├── .github/workflows/     # CI/CD Pipelines (GitHub Actions)
│   ├── infra.yml          # Terraform: fmt → validate → plan → apply
│   ├── api.yml            # Spring Boot: build → test → package
│   └── lambda.yml         # Lambda: lint → package → deploy
├── infra/                 # Terraform IaC (Real AWS)
│   ├── provider.tf        # AWS provider + S3 backend
│   ├── variables.tf       # All configurable variables
│   ├── s3.tf              # S3 + Lifecycle Policies (KEY FEATURE)
│   ├── rds.tf             # VPC + Subnets + RDS PostgreSQL
│   ├── iam.tf             # IAM roles (least privilege)
│   ├── lambda.tf          # Lambda + Layer + EventBridge trigger
│   ├── outputs.tf         # Resource outputs
│   ├── bootstrap.sh       # Backend S3/DynamoDB setup (run once)
│   └── build-layer.sh     # psycopg2 Lambda Layer builder
├── lambda/                # Python Lambda Function
│   ├── handler.py         # Cold data archiver
│   ├── requirements.txt   # Python dependencies
│   ├── db_schema.sql      # Database schema + seed data
│   └── build.sh           # Deployment package builder
└── api/                   # Spring Boot REST API
    ├── pom.xml
    └── src/main/java/com/archival/
        ├── controller/    # REST endpoints
        ├── service/       # Business logic
        ├── model/         # Data models
        └── config/        # AWS SDK config
```

## 🚀 Quick Start

### Prerequisites
- Java 17+, Maven 3.9+
- Python 3.12+
- Terraform 1.5+
- AWS CLI configured (`aws configure`)

### 1. Bootstrap Terraform Backend (one-time)
```bash
cd infra
chmod +x bootstrap.sh build-layer.sh
./bootstrap.sh
```

### 2. Build Lambda Layer
```bash
cd infra
./build-layer.sh
```

### 3. Deploy Infrastructure
```bash
cd infra
cp terraform.tfvars.example terraform.tfvars   # Edit with your values
terraform init
terraform plan
terraform apply
```

### 4. Initialize Database
```bash
# Get the RDS endpoint from Terraform output
RDS_ENDPOINT=$(terraform -chdir=infra output -raw rds_address)

# Apply schema + seed data
PGPASSWORD=ArchivalSecure2025! psql -h $RDS_ENDPOINT -U archival_admin -d archival_db -f lambda/db_schema.sql
```

### 5. Run the API
```bash
cd api

# Set environment variables
export RDS_ENDPOINT=$(terraform -chdir=../infra output -raw rds_endpoint)
export DB_USERNAME=archival_admin
export DB_PASSWORD=ArchivalSecure2025!
export S3_BUCKET=$(terraform -chdir=../infra output -raw s3_bucket_name)
export LAMBDA_FUNCTION_NAME=$(terraform -chdir=../infra output -raw lambda_function_name)

mvn spring-boot:run
```

### 6. API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/archival/trigger` | Trigger cold data archival |
| GET | `/api/v1/archival/objects?prefix=logs/` | List archived objects |
| GET | `/api/v1/archival/cost-report` | Cost savings report |
| GET | `/api/v1/archival/health` | Health check |

## 💰 Cost Optimization

| Storage Class | Cost/GB/Month | Use Case |
|---|---|---|
| S3 Standard | $0.023 | Active data |
| Intelligent-Tiering | $0.013 | Auto-optimized |
| Glacier | $0.004 | Archival (minutes retrieval) |
| Deep Archive | $0.00099 | Long-term (12h retrieval) |

**Example**: 1 TB of logs moved from Standard → Deep Archive saves **~$264/year**.

## 🧹 Cleanup (Destroy All Resources)

```bash
cd infra
terraform destroy -var-file=terraform.tfvars

# Also destroy backend resources
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws s3 rb s3://data-archival-tf-state-${ACCOUNT_ID} --force
aws dynamodb delete-table --table-name data-archival-tf-locks --region eu-north-1
```

## 🛠️ Tech Stack

| Component | Technology |
|---|---|
| API | Spring Boot 3.2 (Java 17) |
| Processing | AWS Lambda (Python 3.12) |
| Database | PostgreSQL 15 (RDS — Free Tier) |
| Storage | S3 (Intelligent-Tiering, Glacier, Deep Archive) |
| Scheduling | EventBridge (daily cron) |
| IaC | Terraform (S3 backend) |
| CI/CD | GitHub Actions |
| Region | eu-north-1 (Stockholm) |
