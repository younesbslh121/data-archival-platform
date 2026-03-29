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
