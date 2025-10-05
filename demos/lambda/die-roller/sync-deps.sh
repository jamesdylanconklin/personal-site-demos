#!/bin/bash
set -e

# TODO: Replace this manual copy step with PyPI package once ast_roller is published
# When published: just use "ast_roller>=0.1.0" in requirements.txt and remove this script

echo "Syncing ast_roller from submodule..."

# Update submodule to latest
git submodule update --init --recursive
cd ast_roller && git pull origin main && cd ..

# Remove old vendored copies
rm -rf src/ast_roller
rm -rf src/ast-roller

# Copy fresh version with correct Python package name
cp -r ast_roller/src/ast_roller src/

echo "Installing pip dependencies..."

# Install pip dependencies into src/ for Lambda packaging
# Remove any existing dependencies first
find src/ -name "lark*" -type d -exec rm -rf {} + 2>/dev/null || true
find src/ -name "*.dist-info" -type d -exec rm -rf {} + 2>/dev/null || true

# Install dependencies
pip install -r src/requirements.txt -t src/ --no-deps

echo "✅ ast_roller synced and dependencies installed successfully"