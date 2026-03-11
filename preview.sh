#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/output"
PORT="${1:-8080}"

# Build first
"$SCRIPT_DIR/build.sh"

echo "Preview at http://localhost:$PORT/boat-0001/  (Ctrl-C to stop)"
python3 -m http.server "$PORT" --directory "$OUTPUT_DIR"
