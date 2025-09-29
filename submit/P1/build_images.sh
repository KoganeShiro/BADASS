#!/bin/sh
set -e

# Build host image
echo "Building host image..."
docker build -t gkubina-host -f _gkubina-1_host .

# Build router image
echo "Building router image..."
docker build -t gkubina-router -f _gkubina-2_router .

echo "✅ Done! Images built:"
docker images | grep gkubina
