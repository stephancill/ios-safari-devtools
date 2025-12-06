#!/bin/bash

# ci_post_clone.sh
# This script runs after Xcode Cloud clones the repository.
# It installs Node.js and pnpm and pre-builds the web extension popup.

set -euo pipefail

echo "=== Installing Node.js via Homebrew ==="
brew install node

echo "=== Installing pnpm ==="
npm install -g pnpm

echo "Node.js version: $(node --version)"
echo "pnpm version: $(pnpm --version)"

# Pre-build the web extension files
# This is more reliable than the Xcode build phase which may have PATH issues
echo "=== Building web extension files ==="
cd "$CI_PRIMARY_REPOSITORY_PATH/popup-app"
pnpm install --frozen-lockfile
pnpm run build

echo "=== Verifying build output ==="
ls -la "$CI_PRIMARY_REPOSITORY_PATH/devtools Extension/Resources/"

echo "ci_post_clone.sh completed successfully"
