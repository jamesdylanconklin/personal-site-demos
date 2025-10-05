#!/bin/bash
set -e

# TODO: Replace this manual copy step with PyPI package once ast_roller is published
# When published: just use "ast_roller>=0.1.0" in requirements.txt and remove this script

echo "Syncing ast_roller from submodule..."

# Update submodule to latest
git submodule update --init --recursive
cd ast-roller && git pull origin main && cd ..

# Remove old vendored copy
rm -rf src/ast_roller

# Copy fresh version
cp -r ast-roller/src/ast_roller src/

echo "✅ ast_roller synced successfully"