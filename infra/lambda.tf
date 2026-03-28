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

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOST               = aws_db_instance.postgres.address
      DB_PORT               = tostring(aws_db_instance.postgres.port)
      DB_NAME               = var.db_name
      DB_USER               = var.db_username
      DB_PASSWORD           = var.db_password
      S3_BUCKET             = aws_s3_bucket.archive.id
      COLD_DATA_THRESHOLD   = tostring(var.cold_data_threshold_days)
    }
  }

  layers = [aws_lambda_layer_version.psycopg2.arn]

  tags = {
    Name = "${var.project_name}-archiver"
  }
}

# ──────────────────────────────────────────────────────────────
# Lambda Layer — psycopg2 for PostgreSQL connectivity
# ──────────────────────────────────────────────────────────────

resource "aws_lambda_layer_version" "psycopg2" {
  layer_name          = "${var.project_name}-psycopg2"
  description         = "psycopg2-binary for PostgreSQL access"
  compatible_runtimes = ["python3.12"]

  filename = "${path.module}/layers/psycopg2-layer.zip"
}

# ──────────────────────────────────────────────────────────────
# CloudWatch — Scheduled Trigger (Daily at 2 AM UTC)
# ──────────────────────────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "daily_archive" {
  name                = "${var.project_name}-daily-archive"
  description         = "Trigger archival Lambda every day at 2 AM UTC"
  schedule_expression = "cron(0 2 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.daily_archive.name
  target_id = "archiver-lambda"
  arn       = aws_lambda_function.archiver.arn
}

resource "aws_lambda_permission" "cloudwatch" {
  statement_id  = "AllowCloudWatchInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.archiver.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_archive.arn
}

# ──────────────────────────────────────────────────────────────
# CloudWatch Log Group
# ──────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.archiver.function_name}"
  retention_in_days = 30
}
