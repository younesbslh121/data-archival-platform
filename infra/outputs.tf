# ──────────────────────────────────────────────────────────────
# Outputs
# ──────────────────────────────────────────────────────────────

# ── S3 ──
output "s3_bucket_name" {
  description = "Name of the archive S3 bucket"
  value       = aws_s3_bucket.archive.id
}

output "s3_bucket_arn" {
  description = "ARN of the archive S3 bucket"
  value       = aws_s3_bucket.archive.arn
}

# ── Lambda ──
output "lambda_function_name" {
  description = "Name of the archiver Lambda function"
  value       = aws_lambda_function.archiver.function_name
}

output "lambda_function_arn" {
  description = "ARN of the archiver Lambda function"
  value       = aws_lambda_function.archiver.arn
}

# ── RDS ──
output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint (host:port)"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_address" {
  description = "RDS PostgreSQL hostname"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.postgres.port
}

# ── VPC ──
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

# ── EventBridge ──
output "eventbridge_rule_arn" {
  description = "ARN of the daily archival EventBridge rule"
  value       = aws_cloudwatch_event_rule.daily_archival.arn
}
