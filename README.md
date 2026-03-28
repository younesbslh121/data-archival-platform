# 🏗️ Intelligent Data Archiving Platform

> **Cost Optimization** — Automatically move cold data (logs, invoices) to cheaper AWS storage tiers and save thousands on cloud bills.

## 🏛️ Architecture

```
┌──────────────┐     ┌──────────────┐     ┌───────────────────────────┐
│  Spring Boot │────▶│  AWS Lambda  │────▶│  PostgreSQL (RDS)         │
│  REST API    │     │  (Python)    │     │  ─ application_logs       │
│  :8080       │     │              │     │  ─ invoices               │
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

## 📁 Project Structure

```
data-archival-platform/
├── .github/workflows/     # CI/CD Pipelines (GitHub Actions)
│   ├── infra.yml          # Terraform: fmt → validate → plan → apply
│   ├── api.yml            # Spring Boot: build → test → package
│   └── lambda.yml         # Lambda: lint → zip → deploy
├── infra/                 # Terraform IaC
│   ├── provider.tf        # AWS provider configuration
│   ├── variables.tf       # All configurable variables
│   ├── s3.tf              # S3 + Lifecycle Policies (KEY FEATURE)
│   ├── rds.tf             # VPC + PostgreSQL RDS
│   ├── iam.tf             # IAM roles (least privilege)
│   ├── lambda.tf          # Lambda + CloudWatch trigger
│   └── outputs.tf         # Resource outputs
├── lambda/                # Python Lambda Function
│   ├── handler.py         # Cold data archiver
│   ├── requirements.txt   # Python dependencies
│   └── db_schema.sql      # Database schema + seed data
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
- AWS CLI configured

### 1. Infrastructure
```bash
cd infra
cp terraform.tfvars.example terraform.tfvars   # Edit with your values
terraform init
terraform plan
terraform apply
```

### 2. Database Setup
```bash
psql -h <RDS_ENDPOINT> -U archival_admin -d archival_db -f lambda/db_schema.sql
```

### 3. API
```bash
cd api
mvn spring-boot:run
```

### 4. API Endpoints

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

## 🛠️ Tech Stack

| Component | Technology |
|---|---|
| API | Spring Boot 3.2 (Java 17) |
| Processing | AWS Lambda (Python 3.12) |
| Database | PostgreSQL 15 (RDS) |
| Storage | S3 (Intelligent-Tiering, Glacier, Deep Archive) |
| IaC | Terraform |
| CI/CD | GitHub Actions |
