#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/output"

# 1. Build the forest.
echo "Building..."
cd "$SCRIPT_DIR"
forester build forest.toml

# 2. Pre-render XML → HTML so browsers never need client-side XSLT.
echo "Pre-rendering XML to HTML..."
find "$OUTPUT_DIR" -mindepth 2 -maxdepth 2 -name "index.xml" | while read -r xml_file; do
    rel="${xml_file#"$OUTPUT_DIR/"}"
    xsltproc --novalid --nonet --output "$OUTPUT_DIR/${rel%.xml}.html" "$OUTPUT_DIR/default.xsl" "$xml_file" &
done
wait
echo "Pre-rendering done."

echo "Done."
