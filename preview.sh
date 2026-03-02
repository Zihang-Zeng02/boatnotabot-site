#!/bin/bash
set -euo pipefail

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FOREST_DIR="$BASE_DIR/forest"
OUTPUT_DIR="$BASE_DIR/output"
PORT="${1:-8080}"

# Build first
echo "Building forest..."
cd "$BASE_DIR"
forester build forest.toml

# Preview
echo "Previewing forest at http://localhost:$PORT... (Ctrl+C to stop)"
cd "$OUTPUT_DIR"
python3 -m http.server "$PORT" -d "$OUTPUT_DIR"
