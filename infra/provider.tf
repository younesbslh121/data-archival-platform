terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # backend "s3" disabled for local development
}

provider "aws" {
  region                      = var.aws_region
  access_key                  = "test"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    s3             = "http://localstack-main:4566"
    lambda         = "http://localstack-main:4566"
    sts            = "http://localstack-main:4566"
    iam            = "http://localstack-main:4566"
    cloudwatch     = "http://localstack-main:4566"
    cloudwatchlogs = "http://localstack-main:4566"
  }

  default_tags {
    tags = {
      Project     = "data-archival-platform"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
