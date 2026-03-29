# ──────────────────────────────────────────────────────────────
# Lambda Function — Cold Data Archiver
# ──────────────────────────────────────────────────────────────

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/lambda_package.zip"
}

resource "aws_lambda_function" "archiver" {
  function_name = "${var.project_name}-archiver"
  description   = "Identifies cold data in RDS and archives to S3"

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"

  role        = aws_iam_role.lambda.arn
  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory

  environment {
    variables = {
      DB_HOST             = "data-archival-postgres"
      DB_PORT             = "5432"
      DB_NAME             = var.db_name
      DB_USER             = var.db_username
      DB_PASSWORD         = var.db_password
      S3_BUCKET           = aws_s3_bucket.archive.id
      COLD_DATA_THRESHOLD = tostring(var.cold_data_threshold_days)
    }
  }

  tags = {
    Name = "${var.project_name}-archiver"
  }
}

# ──────────────────────────────────────────────────────────────
# CloudWatch Log Group
# ──────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.archiver.function_name}"
  retention_in_days = 30
}
