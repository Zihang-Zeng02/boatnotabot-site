#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FOREST_DIR="$SCRIPT_DIR/forest"
OUTPUT_DIR="$FOREST_DIR/output"
PORT="${1:-8080}"

# Build first
echo "Building..."
cd "$FOREST_DIR"
forester build forest.toml
cd "$SCRIPT_DIR"

echo "Preview at http://localhost:$PORT/boat-0001/  (Ctrl-C to stop)"
python3 -m http.server "$PORT" --directory "$OUTPUT_DIR"
