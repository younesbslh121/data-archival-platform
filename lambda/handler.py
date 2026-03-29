"""
Data Archival Lambda Handler
============================
Connects to PostgreSQL (RDS), identifies cold data (logs & invoices),
exports them as JSON to S3, and marks records as archived.
"""

import os
import json
import logging
import boto3
import psycopg2
from datetime import datetime, timedelta, timezone

# ── Configuration ──────────────────────────────────────────────

logger = logging.getLogger()
logger.setLevel(logging.INFO)

DB_HOST = os.environ["DB_HOST"]
DB_PORT = int(os.environ.get("DB_PORT", 5432))
DB_NAME = os.environ["DB_NAME"]
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]
S3_BUCKET = os.environ["S3_BUCKET"]
THRESHOLD = int(os.environ.get("COLD_DATA_THRESHOLD", 90))

s3_client = boto3.client("s3")


# ── Database Connection ───────────────────────────────────────

def get_db_connection():
    """Create a PostgreSQL connection."""
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        connect_timeout=10,
    )


# ── Cold Data Queries ─────────────────────────────────────────

COLD_DATA_QUERIES = {
    "logs": {
        "select": """
            SELECT id, level, message, source, created_at
            FROM application_logs
            WHERE created_at < %s
              AND archived = FALSE
            ORDER BY created_at ASC
            LIMIT 1000
        """,
        "update": """
            UPDATE application_logs
            SET archived = TRUE, archived_at = NOW()
            WHERE id = ANY(%s)
        """,
    },
    "invoices": {
        "select": """
            SELECT id, invoice_number, client_name, amount, currency,
                   issued_at, paid_at
            FROM invoices
            WHERE issued_at < %s
              AND archived = FALSE
            ORDER BY issued_at ASC
            LIMIT 1000
        """,
        "update": """
            UPDATE invoices
            SET archived = TRUE, archived_at = NOW()
            WHERE id = ANY(%s)
        """,
    },
}


# ── S3 Upload ─────────────────────────────────────────────────

def upload_to_s3(records: list, data_type: str, batch_timestamp: str) -> str:
    """Upload a batch of records to S3 as JSON."""
    key = f"{data_type}/{batch_timestamp}/batch_{len(records)}.json"

    body = json.dumps(records, default=str, indent=2)

    s3_client.put_object(
        Bucket=S3_BUCKET,
        Key=key,
        Body=body,
        ContentType="application/json",
        Metadata={
            "data-type": data_type,
            "record-count": str(len(records)),
            "archived-at": batch_timestamp,
        },
    )

    logger.info(
        "Uploaded %d %s records -> s3://%s/%s",
        len(records), data_type, S3_BUCKET, key
    )
    return key


# ── Archive Logic ─────────────────────────────────────────────

def archive_cold_data(data_type: str, conn) -> dict:
    """Identify, export, and mark cold data for a given type."""
    cutoff_date = datetime.now(timezone.utc) - timedelta(days=THRESHOLD)
    batch_timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d_%H-%M-%S")

    queries = COLD_DATA_QUERIES[data_type]

    with conn.cursor() as cur:
        # 1. Fetch cold records
        cur.execute(queries["select"], (cutoff_date,))
        columns = [desc[0] for desc in cur.description]
        rows = cur.fetchall()

        if not rows:
            logger.info("No cold %s found (threshold: %d days)", data_type, THRESHOLD)
            return {"data_type": data_type, "archived_count": 0, "s3_key": None}

        records = [dict(zip(columns, row)) for row in rows]
        record_ids = [r["id"] for r in records]

        # 2. Upload to S3
        s3_key = upload_to_s3(records, data_type, batch_timestamp)

        # 3. Mark as archived in DB
        cur.execute(queries["update"], (record_ids,))
        conn.commit()

        logger.info("Archived %d %s records", len(records), data_type)

        return {
            "data_type": data_type,
            "archived_count": len(records),
            "s3_key": s3_key,
            "cutoff_date": str(cutoff_date),
        }


# ── Lambda Entry Point ───────────────────────────────────────

def lambda_handler(event, context):
    """
    Main Lambda handler.
    Triggered by CloudWatch Events (daily) or Spring Boot API (on-demand).
    """
    logger.info("Starting cold data archival - threshold: %d days", THRESHOLD)
    logger.info("Event: %s", json.dumps(event, default=str))

    results = []
    conn = None

    try:
        conn = get_db_connection()
        logger.info("Connected to PostgreSQL successfully")

        for data_type in COLD_DATA_QUERIES:
            result = archive_cold_data(data_type, conn)
            results.append(result)

        total_archived = sum(r["archived_count"] for r in results)

        response = {
            "statusCode": 200,
            "body": {
                "message": "Archival complete - %d records processed" % total_archived,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "results": results,
            },
        }

        logger.info("Archival complete: %s", json.dumps(response, default=str))
        return response

    except Exception as e:
        logger.error("Archival failed: %s", str(e), exc_info=True)
        return {
            "statusCode": 500,
            "body": {"error": str(e)},
        }

    finally:
        if conn:
            conn.close()
            logger.info("Database connection closed")
