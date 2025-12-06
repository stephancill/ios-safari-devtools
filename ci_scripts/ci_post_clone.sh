#!/bin/bash

# ci_post_clone.sh
# This script runs after Xcode Cloud clones the repository.
# It installs Node.js and pnpm for building the web extension popup.

set -euo pipefail

echo "Installing Node.js via Homebrew..."
brew install node

echo "Installing pnpm..."
npm install -g pnpm

echo "Node.js version: $(node --version)"
echo "pnpm version: $(pnpm --version)"

echo "ci_post_clone.sh completed successfully"
