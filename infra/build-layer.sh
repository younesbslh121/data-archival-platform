#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Build psycopg2 Lambda Layer for Python 3.12
# ═══════════════════════════════════════════════════════════════
# Creates a Lambda Layer zip with psycopg2-binary compiled
# for Amazon Linux 2 (x86_64)
# Uses Python's zipfile module (no 'zip' command needed)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAYER_DIR="${SCRIPT_DIR}/layers"
BUILD_DIR="${LAYER_DIR}/python"
OUTPUT_FILE="${LAYER_DIR}/psycopg2-layer.zip"

echo "🧹 Cleaning previous build..."
rm -rf "${BUILD_DIR}" "${OUTPUT_FILE}"
mkdir -p "${BUILD_DIR}"

echo "📦 Installing psycopg2-binary for Lambda..."
pip install psycopg2-binary==2.9.9 -t "${BUILD_DIR}/" --quiet \
  --platform manylinux2014_x86_64 \
  --implementation cp \
  --python-version 3.12 \
  --only-binary=:all:

echo "🗜️  Creating layer zip..."
python3 -c "
import zipfile, os

output = '${OUTPUT_FILE}'
base = '${LAYER_DIR}'

with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk(os.path.join(base, 'python')):
        # Skip __pycache__ directories
        dirs[:] = [d for d in dirs if d != '__pycache__']
        for f in files:
            if f.endswith('.pyc'):
                continue
            filepath = os.path.join(root, f)
            arcname = os.path.relpath(filepath, base)
            zf.write(filepath, arcname)

print(f'   Created: {output}')
"

echo "🧹 Cleaning build directory..."
rm -rf "${BUILD_DIR}"

SIZE=$(du -h "${OUTPUT_FILE}" | cut -f1)
echo "✅ Lambda Layer created: ${OUTPUT_FILE}"
echo "   Size: ${SIZE}"
