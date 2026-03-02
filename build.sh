#!/bin/bash
set -euo pipefail

# Build
echo "Building forest..."
forester build forest.toml
