#!/bin/bash
# ═══════════════════════════════════════════════════
# Lambda Deployment Package Builder
# ═══════════════════════════════════════════════════
# Packages handler.py with dependencies for AWS Lambda

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="${SCRIPT_DIR}/package"
OUTPUT_FILE="${SCRIPT_DIR}/lambda_deployment.zip"

echo "🧹 Cleaning previous build..."
rm -rf "${PACKAGE_DIR}" "${OUTPUT_FILE}"

echo "📦 Installing dependencies..."
mkdir -p "${PACKAGE_DIR}"
pip install -r "${SCRIPT_DIR}/requirements.txt" -t "${PACKAGE_DIR}/" --quiet

echo "📄 Copying handler..."
cp "${SCRIPT_DIR}/handler.py" "${PACKAGE_DIR}/"

echo "🗜️  Creating deployment package..."
cd "${PACKAGE_DIR}"
zip -r "${OUTPUT_FILE}" . -x "__pycache__/*" "*.pyc" > /dev/null

echo "✅ Lambda package created: ${OUTPUT_FILE}"
echo "   Size: $(du -h "${OUTPUT_FILE}" | cut -f1)"
