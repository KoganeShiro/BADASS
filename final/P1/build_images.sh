#!/bin/sh
set -e

# Build host image
echo "Building host image..."
docker build -t host_gkubina -f _gkubina_host .

# Build router image
echo "Building router image..."
docker build -t router_gkubina -f _gkubina_router .

echo "✅ Done! Images built:"
docker images | grep gkubina
