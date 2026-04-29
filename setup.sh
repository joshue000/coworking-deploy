#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}==>${NC} $*"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $*"; }
error()   { echo -e "${RED}[error]${NC} $*" >&2; exit 1; }

# ── Preflight ──────────────────────────────────────────────────────────────────

command -v git    >/dev/null 2>&1 || error "git is not installed"
command -v docker >/dev/null 2>&1 || error "docker is not installed"
docker compose version >/dev/null 2>&1 || error "docker compose plugin is not available"

# ── Submodules ─────────────────────────────────────────────────────────────────

info "Initializing git submodules..."
git submodule update --init --recursive

# ── Environment ────────────────────────────────────────────────────────────────

if [ ! -f .env ]; then
  cp .env.example .env
  info "Created .env from .env.example"
  warn "Edit .env and set a strong API_KEY before starting in production"
else
  info ".env already exists — skipping copy"
fi

# ── Docker stack ───────────────────────────────────────────────────────────────

info "Building and starting all services..."
docker compose up --build -d

# ── Status ─────────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}All services are up.${NC}"
echo ""
echo "  API       →  http://localhost:3000"
echo "  Swagger   →  http://localhost:3000/api-docs"
echo "  Frontend  →  http://localhost:80"
echo "  MQTT      →  localhost:1883"
echo ""
echo "To run the IoT simulator (requires place/space IDs from the API):"
echo "  cd iot-simulator && npm install"
echo "  node index.js --site-id <placeId> --office-id <spaceId>"
echo ""
echo "To stop everything:"
echo "  docker compose down"
