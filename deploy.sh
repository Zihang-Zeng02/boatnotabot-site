#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/output"

cd "$OUTPUT_DIR"

# Verify we're on the right branch before touching anything.
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$CURRENT_BRANCH" != "deploy-dev" ]]; then
    echo "Error: expected branch 'deploy-dev', but currently on '$CURRENT_BRANCH'. Aborting." >&2
    exit 1
fi

# Stage all changes (new files, modifications, deletions).
git add -A

# Nothing to do if the tree is clean.
if git diff --cached --quiet; then
    echo "Nothing to commit — deploy-dev branch is already up to date."
    exit 0
fi

# Commit with a timestamp so every deploy is identifiable.
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "Deploy: $TIMESTAMP"

# Push to deploy-dev for preview.
git push origin deploy-dev

# If --prod flag is passed, also push to deploy (production).
if [[ "${1:-}" == "--prod" ]]; then
    git push origin deploy-dev:deploy
    echo "Done. Site deployed to production (origin @ deploy)."
else
    echo "Done. Preview pushed to origin @ deploy-dev."
    echo "To deploy to production: ./deploy.sh --prod"
fi
