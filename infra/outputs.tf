output "s3_bucket_name" {
  description = "Name of the archive S3 bucket"
  value       = aws_s3_bucket.archive.id
}

output "s3_bucket_arn" {
  description = "ARN of the archive S3 bucket"
  value       = aws_s3_bucket.archive.arn
}

output "lambda_function_name" {
  description = "Name of the archiver Lambda function"
  value       = aws_lambda_function.archiver.function_name
}

output "lambda_function_arn" {
  description = "ARN of the archiver Lambda function"
  value       = aws_lambda_function.archiver.arn
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.postgres.db_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}
