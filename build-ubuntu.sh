#!/usr/bin/env bash
set -e

echo "=== Baloot iOS Native — Build & Test on Ubuntu ==="

# Check if Swift is installed locally or via Docker
if command -v swift >/dev/null 2>&1; then
    echo "Running Swift directly on host..."
    swift --version
    swift test
    swift build
elif command -v docker >/dev/null 2>&1; then
    echo "Using Docker (swift:6.1-jammy) to build and run test suite..."
    docker run --rm -v "$(pwd):/app" -w /app swift:6.1-jammy bash -c "swift test && swift build"
else
    echo "Error: Neither Swift nor Docker was found in your Ubuntu environment."
    echo "Please install Docker or Swift 6 to build and test locally."
    exit 1
fi

echo "=== All tests passed successfully! ==="
