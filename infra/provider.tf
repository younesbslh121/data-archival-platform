# ──────────────────────────────────────────────────────────────
# Terraform Configuration — Real AWS Provider
# ──────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote backend for state management
  backend "s3" {
    bucket       = "data-archival-tf-state-690058257499"
    key          = "data-archival-platform/terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "data-archival-platform"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
