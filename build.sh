#!/bin/bash
set -euo pipefail

# Resolve absolute paths from the script's own location, so it works regardless of CWD.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FOREST_DIR="$SCRIPT_DIR/forest"
OUTPUT_DIR="$FOREST_DIR/output"

# Determine XSLT processor: prefer native xsltproc, fall back to prerender.js (Node.js + SaxonJS).
if command -v xsltproc &>/dev/null; then
    XSLT_TOOL="xsltproc"
elif command -v node &>/dev/null; then
    XSLT_TOOL="node"
    # Ensure build-time dependencies (xslt3 / saxon-js) are installed.
    if [ ! -f "$SCRIPT_DIR/node_modules/.bin/xslt3" ]; then
        echo "Installing build dependencies..."
        npm install --prefix "$SCRIPT_DIR" --omit=prod
    fi
else
    echo "Error: no XSLT processor found. Install xsltproc (sudo apt install xsltproc) or Node.js." >&2
    exit 1
fi

# 1. Clean the output directory.
#    Use -maxdepth 1 to only touch immediate children, then rm -rf each one.
#    Exclude .git (worktree pointer file) and any hand-placed index.html.
echo "Cleaning $OUTPUT_DIR..."
find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 \
    ! -name '.git' \
    ! -name 'index.html' \
    ! -name '_redirects' \
    -exec rm -rf {} +

# 2. Build the forest. forester expects to run from the directory containing forest.toml.
echo "Building..."
cd "$FOREST_DIR"
forester build forest.toml
cd "$SCRIPT_DIR"

# 3. Pre-render XML → HTML so browsers never need client-side XSLT.
#    (XSLTProcessor and xml-stylesheet processing instructions are being removed from browsers.)
echo "Pre-rendering XML to HTML..."
if [ "$XSLT_TOOL" = "xsltproc" ]; then
    # Fast native binary — run all pages in parallel.
    find "$OUTPUT_DIR" -mindepth 2 -maxdepth 2 -name "index.xml" | while read -r xml_file; do
        rel="${xml_file#"$OUTPUT_DIR/"}"
        xsltproc --novalid --nonet --output "$OUTPUT_DIR/${rel%.xml}.html" "$OUTPUT_DIR/default.xsl" "$xml_file" &
    done
    wait
else
    # Single Node.js process: compile stylesheet once (cached), transform all pages concurrently.
    node "$SCRIPT_DIR/prerender.js" "$OUTPUT_DIR"
fi
echo "Pre-rendering done."

echo "Done. Commit and push forest/output to deploy the site."
