#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
NC='\033[0m'

info() { echo -e "${GREEN}==>${NC} $*"; }

info "Starting core services (mosquitto, postgres, api, frontend)..."
docker compose up -d

echo ""
echo -e "${GREEN}Services are up.${NC}"
echo ""
echo "  API       →  http://localhost:3000"
echo "  Swagger   →  http://localhost:3000/api-docs"
echo "  Frontend  →  http://localhost:80"
echo "  MQTT      →  localhost:1883"
echo ""
echo "To run the IoT simulator (requires place/space IDs from the API):"
echo "  cd iot-simulator && npm install && cp .env.example .env"
echo "  node index.js --site-id <placeId> --office-id <spaceId>"
echo ""
echo "To stop everything:"
echo "  ./stop.sh"
