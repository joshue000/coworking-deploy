#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
NC='\033[0m'

info() { echo -e "${GREEN}==>${NC} $*"; }

info "Stopping all services..."
docker compose down

echo ""
echo -e "${GREEN}All services stopped.${NC}"
echo ""
echo "To also remove volumes (resets database):"
echo "  docker compose down -v"
