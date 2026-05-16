# ──────────────────────────────────────────────────────────────
# Lambda Function — Cold Data Archiver
# ──────────────────────────────────────────────────────────────

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/lambda_package.zip"
  excludes    = ["__pycache__", "*.pyc", "build.sh", "run_archival.py"]
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

  # Lambda runs in private subnets to access RDS
  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  # Lambda Layer for psycopg2 (pre-compiled for Amazon Linux 2)
  layers = [aws_lambda_layer_version.psycopg2.arn]

  environment {
    variables = {
      DB_HOST             = aws_db_instance.postgres.address
      DB_PORT             = tostring(aws_db_instance.postgres.port)
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

  depends_on = [
    aws_iam_role_policy.lambda_s3,
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy_attachment.lambda_vpc,
    aws_cloudwatch_log_group.lambda,
    aws_nat_gateway.main,
  ]
}

# ──────────────────────────────────────────────────────────────
# Lambda Layer — psycopg2 for PostgreSQL
# ──────────────────────────────────────────────────────────────

resource "aws_lambda_layer_version" "psycopg2" {
  filename            = "${path.module}/layers/psycopg2-layer.zip"
  layer_name          = "${var.project_name}-psycopg2"
  compatible_runtimes = ["python3.12"]
  description         = "psycopg2-binary compiled for Amazon Linux 2"
}

# ──────────────────────────────────────────────────────────────
# CloudWatch Log Group
# ──────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-archiver"
  retention_in_days = 14

  tags = {
    Name = "${var.project_name}-lambda-logs"
  }
}

# ──────────────────────────────────────────────────────────────
# EventBridge Rule — Daily Archival Trigger
# ──────────────────────────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "daily_archival" {
  name                = "${var.project_name}-daily-archival"
  description         = "Triggers Lambda daily at 2 AM UTC to archive cold data"
  schedule_expression = "cron(0 2 * * ? *)"

  tags = {
    Name = "${var.project_name}-daily-trigger"
  }
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.daily_archival.name
  target_id = "archival-lambda"
  arn       = aws_lambda_function.archiver.arn

  input = jsonencode({
    source = "eventbridge-scheduled"
  })
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.archiver.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_archival.arn
}
