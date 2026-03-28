# ──────────────────────────────────────────────────────────────
# S3 Bucket — Archived Data Storage
# ──────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "archive" {
  bucket = "${var.s3_bucket_name}-${var.environment}"

  tags = {
    Name = "Data Archival Storage"
  }
}

# Enable versioning for data protection
resource "aws_s3_bucket_versioning" "archive" {
  bucket = aws_s3_bucket.archive.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption (AES-256)
resource "aws_s3_bucket_server_side_encryption_configuration" "archive" {
  bucket = aws_s3_bucket.archive.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "archive" {
  bucket = aws_s3_bucket.archive.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ──────────────────────────────────────────────────────────────
# S3 Lifecycle Policies — Cost Optimization (THE KEY FEATURE)
# ──────────────────────────────────────────────────────────────

resource "aws_s3_bucket_lifecycle_configuration" "archive" {
  bucket = aws_s3_bucket.archive.id

  # Rule 1: Logs → Intelligent-Tiering → Glacier → Deep Archive
  rule {
    id     = "logs-lifecycle"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    transition {
      days          = var.intelligent_tiering_days
      storage_class = "INTELLIGENT_TIERING"
    }

    transition {
      days          = var.glacier_days
      storage_class = "GLACIER"
    }

    transition {
      days          = var.glacier_deep_archive_days
      storage_class = "DEEP_ARCHIVE"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  # Rule 2: Invoices — same tiering but longer retention
  rule {
    id     = "invoices-lifecycle"
    status = "Enabled"

    filter {
      prefix = "invoices/"
    }

    transition {
      days          = var.intelligent_tiering_days
      storage_class = "INTELLIGENT_TIERING"
    }

    transition {
      days          = var.glacier_days
      storage_class = "GLACIER"
    }

    transition {
      days          = var.glacier_deep_archive_days
      storage_class = "DEEP_ARCHIVE"
    }

    # Invoices: keep 7 years for compliance
    expiration {
      days = 2555
    }
  }

  # Rule 3: Cleanup incomplete multipart uploads
  rule {
    id     = "cleanup-multipart"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ──────────────────────────────────────────────────────────────
# S3 Intelligent-Tiering Configuration
# ──────────────────────────────────────────────────────────────

resource "aws_s3_bucket_intelligent_tiering_configuration" "archive" {
  bucket = aws_s3_bucket.archive.id
  name   = "full-tiering"

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 125
  }
}
