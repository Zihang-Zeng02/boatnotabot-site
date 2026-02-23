#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/forest/output"

cd "$OUTPUT_DIR"

# Verify we're on the right branch before touching anything.
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$CURRENT_BRANCH" != "deploy" ]]; then
    echo "Error: expected branch 'deploy', but currently on '$CURRENT_BRANCH'. Aborting." >&2
    exit 1
fi

# Stage all changes (new files, modifications, deletions).
git add -A

# Nothing to do if the tree is clean.
if git diff --cached --quiet; then
    echo "Nothing to commit — deploy branch is already up to date."
    exit 0
fi

# Commit with a timestamp so every deploy is identifiable.
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "Deploy: $TIMESTAMP"

# Push to the deploy branch on origin (SSH).
git push origin deploy

echo "Done. Site deployed to Zihang-Zeng02/boatnotabot-site @ deploy."
