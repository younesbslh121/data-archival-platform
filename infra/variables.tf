variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "data-archival"
}

# ──────────────────────────────────────────
# S3 Configuration
# ──────────────────────────────────────────

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for archived data"
  type        = string
  default     = "data-archival-storage"
}

variable "intelligent_tiering_days" {
  description = "Days before transitioning objects to S3 Intelligent-Tiering"
  type        = number
  default     = 30
}

variable "glacier_days" {
  description = "Days before transitioning objects to S3 Glacier"
  type        = number
  default     = 90
}

variable "glacier_deep_archive_days" {
  description = "Days before transitioning objects to S3 Glacier Deep Archive"
  type        = number
  default     = 365
}

# ──────────────────────────────────────────
# RDS Configuration
# ──────────────────────────────────────────

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "archival_db"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "archival_admin"
  sensitive   = true
}

variable "db_password" {
  description = "PostgreSQL master password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

# ──────────────────────────────────────────
# Lambda Configuration
# ──────────────────────────────────────────

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300
}

variable "lambda_memory" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 256
}

variable "cold_data_threshold_days" {
  description = "Number of days after which data is considered cold"
  type        = number
  default     = 90
}
