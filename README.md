# Darient — Coworking Platform

Central repository for the Darient workspace reservation system. Orchestrates all services via a single `docker-compose.yml`.

## Architecture

```
coworking-deploy/           ← this repo (orchestrator)
├── coworking-api/          ← submodule: REST API + IoT backend
├── coworking-frontend/     ← submodule: React admin dashboard
└── iot-simulator/          ← submodule: MQTT device simulator
```

### Services (Docker)

| Service | Description | Port |
|---|---|---|
| `mosquitto` | Eclipse Mosquitto 2.0 MQTT broker | `1883` |
| `postgres` | PostgreSQL 16 database | `5432` |
| `api` | Node.js REST API + MQTT subscriber | `3000` |
| `frontend` | React app served via Nginx | `80` |

The IoT simulator is **not** a Docker service — it runs as a Node.js process and connects to the broker on `localhost:1883`.

---

## Prerequisites

- Git
- Docker + Docker Compose plugin (`docker compose version`)
- Node.js 20+ (only needed to run the IoT simulator)

---

## Quick Start

### 1. Clone with submodules

```bash
git clone --recurse-submodules <repo-url>
cd coworking-deploy
```

If you already cloned without `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

### 2. Configure your API key

Open `.env` (created automatically by `setup.sh`) and set `API_KEY` to a strong secret:

```bash
API_KEY=your-secret-key-here
```

### 3. First-time setup

Builds images, initializes submodules, and starts all services:

```bash
./setup.sh
```

This will:
1. Initialize submodules (if not done already)
2. Create `.env` from `.env.example`
3. Build Docker images and start all services

### Subsequent runs

After the initial setup, use `start.sh` to bring up the stack without rebuilding:

```bash
./start.sh
```

> Use `./setup.sh` again only if you need to rebuild images (e.g. after pulling changes).

---

## Manual Setup

If you prefer to run steps individually:

```bash
# 1. Initialize submodules
git submodule update --init --recursive

# 2. Create environment file
cp .env.example .env
# Edit .env — set API_KEY at minimum

# 3. Start all services
docker compose up --build -d
```

---

## Environment Variables

Copy `.env.example` to `.env` and adjust the values. The most important ones:

| Variable | Description |
|---|---|
| `API_KEY` | **Required.** Static key for API authentication (`x-api-key` header) |
| `POSTGRES_PASSWORD` | PostgreSQL password (change in production) |
| `VITE_API_BASE_URL` | URL the **browser** uses to reach the API. Default: `http://localhost:3000` |
| `FRONTEND_PORT` | Host port for the frontend. Default: `80` |
| `PORT` | Host port for the API. Default: `3000` |

> `VITE_API_BASE_URL` is baked into the frontend bundle at build time. If you change it, rebuild the frontend container: `docker compose up --build -d frontend`

---

## Accessing the Services

| URL | Description |
|---|---|
| `http://localhost:80` | Frontend dashboard |
| `http://localhost:3000` | REST API |
| `http://localhost:3000/api-docs` | Swagger UI (interactive API docs) |
| `http://localhost:3000/health` | Health check (no auth required) |
| `localhost:1883` | MQTT broker |
| `localhost:5432` | PostgreSQL |

---

## IoT Simulator

The simulator sends synthetic MQTT telemetry for a specific space. It requires a `placeId` and `spaceId` that exist in the database — create them first via the frontend or the API.

### Setup

```bash
cd iot-simulator
npm install
cp .env.example .env  # adjust MQTT_URL if needed
```

### Normal operation (no alerts)

Sends readings well within thresholds — CO2 around 600 ppm, 2 people in the space:

```bash
BASE_CO2_PPM=600 BASE_OCCUPANCY=2 node index.js --site-id <placeId> --office-id <spaceId>
```

### Trigger a CO2 alert

CO2 above 1000 ppm sustained for ~5 minutes opens a CO2 alert:

```bash
BASE_CO2_PPM=1200 node index.js --site-id <placeId> --office-id <spaceId>
```

### Trigger an occupancy alert

Set occupancy above the space's configured capacity (e.g. capacity = 10, occupancy = 13).
The alert opens after ~2 minutes of sustained overcapacity:

```bash
BASE_OCCUPANCY=13 node index.js --site-id <placeId> --office-id <spaceId>
```

### Trigger both alerts at once

```bash
BASE_CO2_PPM=1300 BASE_OCCUPANCY=13 node index.js --site-id <placeId> --office-id <spaceId>
```

### Run multiple simulators in parallel

Each simulator instance represents one physical device. Run in separate terminals:

```bash
node index.js --site-id <placeId> --office-id <spaceId1>
node index.js --site-id <placeId> --office-id <spaceId2>
```

### Environment variables

| Variable | Default | Description |
|---|---|---|
| `MQTT_URL` | `mqtt://localhost:1883` | MQTT broker URL |
| `INTERVAL_SEC` | `10` | Telemetry publish interval in seconds |
| `BASE_CO2_PPM` | `800` | Base CO2 reading (ppm) |
| `BASE_OCCUPANCY` | `3` | Base occupancy count |
| `BASE_TEMP_C` | `23` | Base temperature (°C) |
| `BASE_HUMIDITY_PCT` | `48` | Base humidity (%) |
| `BASE_POWER_W` | `120` | Base power consumption (W) |

### MQTT topics

The simulator publishes to:
- `sites/{placeId}/offices/{spaceId}/telemetry` — sensor readings
- `sites/{placeId}/offices/{spaceId}/reported` — confirmed device state

And subscribes to:
- `sites/{placeId}/offices/{spaceId}/desired` — configuration updates from the cloud

---

## Useful Commands

```bash
# View logs for all services
docker compose logs -f

# View logs for a specific service
docker compose logs -f api

# Stop all services
docker compose down

# Stop and remove volumes (resets database)
docker compose down -v

# Rebuild a specific service
docker compose up --build -d frontend
```

---

## Submodules

This repo treats the three projects as git submodules. Each submodule is an independent repository with its own history.

```bash
# Update all submodules to latest remote commits
git submodule update --remote --merge

# Work inside a submodule
cd coworking-api
git checkout main
git pull
```

---

## Project READMEs

For detailed documentation of each service:

- [`coworking-api/README.md`](coworking-api/README.md) — API endpoints, architecture, environment variables, test suite
- [`coworking-frontend/README.md`](coworking-frontend/README.md) — frontend setup, project structure, authentication flow
- [`iot-simulator/README.md`](iot-simulator/README.md) — MQTT topics, alert rules, digital twin spec
