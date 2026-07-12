# n8n with PostgreSQL, Redis, Worker, Task Runners, and Alloy

A production-ready Docker Compose stack for n8n 2.0+ with:

- **PostgreSQL** — persistent workflow & execution data
- **Redis** — Bull queue backend for execution routing
- **n8n (main)** — web UI, API, and workflow editor
- **n8n-worker** — dedicated execution worker (queue mode)
- **n8n-runner** — task runner sidecar for Code nodes (JavaScript/Python)
- **n8n-worker-runner** — task runner attached to the worker
- **Alloy** — OTLP trace receiver, forwards to Grafana Cloud Tempo

---

## Architecture

```
                    ┌─────────────┐
                    │   n8n       │◄── Web UI (port 5678)
                    │  (main)     │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
         ┌─────────┐ ┌───────────┐ ┌────────────┐
         │ PostgreSQL│ │   Redis   │ │ n8n-worker │
         │  (DB)     │ │  (Queue)  │ │  (Worker)  │
         └─────────┘ └───────────┘ └─────┬──────┘
                                         │
                                  ┌──────┴──────┐
                                  ▼             ▼
                            ┌──────────┐ ┌────────────┐
                            │n8n-runner│ │n8n-worker- │
                            │ (tasks)  │ │ runner     │
                            └──────────┘ └────────────┘

         ┌──────────────────────────────────────┐
         │              Alloy                   │
         │  Receives OTLP traces from n8n       │
         │  Forwards to Grafana Cloud Tempo     │
         └──────────────────────────────────────┘
```

All services communicate over the internal `n8n-net` bridge network.

---

## Quick Start

```bash
# 1. Copy the example env file and fill in your values
cp .env.example .env

# 2. Generate secure secrets (run once)
# ENCRYPTION_KEY:
openssl rand -hex 32
# RUNNERS_AUTH_TOKEN:
openssl rand -hex 32
# REDIS_PASSWORD:
openssl rand -hex 32
# POSTGRES_PASSWORD & POSTGRES_NON_ROOT_PASSWORD:
openssl rand -hex 16

# 3. Paste the generated values into .env, then start
docker compose up -d
```

n8n will be available at **http://localhost:5678**

---

## Stop & Cleanup

```bash
# Stop containers (preserves volumes)
docker compose stop

# Stop AND remove containers, networks (keeps volumes)
docker compose down

# Full cleanup including volumes ⚠️ DATA LOSS
docker compose down -v
```

---

## Configuration

All configuration lives in `.env` (copy from `.env.example`).

| Variable | Description | Required |
|----------|-------------|----------|
| `N8N_VERSION` | n8n image tag (e.g., `2.25.7`) | ✅ |
| `POSTGRES_VERSION` | PostgreSQL image tag (e.g., `18.4`) | ✅ |
| `REDIS_VERSION` | Redis image tag (e.g., `8.8.0-alpine`) | ✅ |
| `POSTGRES_USER` | Postgres superuser name | ✅ |
| `POSTGRES_PASSWORD` | Postgres superuser password | ✅ |
| `POSTGRES_DB` | Database name (default: `n8n`) | ✅ |
| `POSTGRES_NON_ROOT_USER` | App DB user (created by `init-data.sh`) | ✅ |
| `POSTGRES_NON_ROOT_PASSWORD` | App DB user password | ✅ |
| `ENCRYPTION_KEY` | **32-byte hex** — encrypts credentials in DB | ✅ |
| `RUNNERS_AUTH_TOKEN` | **Shared secret** — n8n ↔ task runner auth | ✅ |
| `REDIS_PASSWORD` | Redis auth password | ✅ |
| `N8N_OTEL_TRACES_SAMPLE_RATE` | Trace sampling (0.0–1.0) | ✅ |
| `N8N_ENDPOINT_HEALTH` | Health endpoint path (default: `health/live`) | ✅ |
| `WEBHOOK_URL` | Public URL for webhooks (update for prod) | ✅ |
| `GRAFANA_CLOUD_TRACES_INSTANCE_ID` | Grafana Cloud traces instance ID | ✅ |
| `GRAFANA_CLOUD_API_KEY` | Grafana Cloud API key | ✅ |

### Secrets generation cheatsheet

```bash
# ENCRYPTION_KEY (32 bytes = 64 hex chars)
openssl rand -hex 32

# RUNNERS_AUTH_TOKEN (32 bytes)
openssl rand -hex 32

# REDIS_PASSWORD (32 bytes)
openssl rand -hex 32

# POSTGRES_PASSWORD / POSTGRES_NON_ROOT_PASSWORD (16 bytes)
openssl rand -hex 16
```

---

## What `init-data.sh` Does

Runs automatically on first PostgreSQL startup. Creates the non-root database user (`POSTGRES_NON_ROOT_USER`) with:

- `CREATE USER` with the given password
- `GRANT ALL PRIVILEGES ON DATABASE` to that user
- `GRANT CREATE ON SCHEMA public` so n8n can manage its own schema migrations

> **Note**: If you change `POSTGRES_NON_ROOT_USER` / `POSTGRES_NON_ROOT_PASSWORD` after the first run, you must either run the SQL manually or wipe the `db_storage` volume (`docker compose down -v`).

---

## Observability (Built-in)

| Feature | Config | Notes |
|---------|--------|-------|
| **OpenTelemetry traces** | `N8N_OTEL_ENABLED=true` | Exports to `http://alloy:4318` — sidecar Alloy receives traces and forwards to Grafana Cloud Tempo |
| **Prometheus metrics** | `N8N_METRICS=true` | Scrape at `http://localhost:5678/metrics` |
| **JSON logging** | `N8N_LOG_FORMAT=json` | Structured logs to stdout for log aggregators |
| **Queue metrics** | `N8N_METRICS_INCLUDE_QUEUE_METRICS=true` | Bull queue depth, latency, etc. |

---

## Resource Requirements

The compose file sets CPU/memory limits. Minimum host resources recommended:

| Service | CPU Limit | Memory Limit |
|---------|-----------|--------------|
| n8n (main) | 2 cores | 1 GB |
| n8n-worker | 4 cores | 2 GB |
| n8n-runner | 1 core | 512 MB |
| n8n-worker-runner | 1 core | 512 MB |
| PostgreSQL | 2 cores | 1 GB |
| Redis | 1 core | 256 MB |
| Alloy | 0.5 cores | 256 MB |
| **Total** | **~11.5 cores** | **~5.5 GB** |

Adjust `deploy.resources.limits` in `docker-compose.yml` if your host has less.

---

## Persistence

Named Docker volumes (survive `docker compose down`):

| Volume | Service | Contents |
|--------|---------|----------|
| `db_storage` | postgres | `/var/lib/postgresql` — all DB data |
| `n8n_storage` | n8n, n8n-worker | `/home/node/.n8n` — binary data, config, custom nodes |
| `redis_storage` | redis | `/data` — queue persistence (AOF) |
| `alloy_data` | alloy | `/var/lib/alloy/data` — trace buffering |

Backup strategy: `docker run --rm -v db_storage:/data -v $(pwd):/backup alpine tar czf /backup/db_backup_$(date +%F).tar.gz -C /data .`

---

## Common Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| `n8n` healthcheck fails | Alloy sidecar not running | `docker compose up -d alloy` or disable OTel with `N8N_OTEL_ENABLED=false` |
| `POSTGRES_NON_ROOT_USER` not created | `init-data.sh` didn't run (volume already existed) | `docker compose down -v && docker compose up -d` |
| Task runners won't connect | `RUNNERS_AUTH_TOKEN` mismatch | Ensure identical value in `.env` for all services |
| Webhook URLs show `localhost` | `WEBHOOK_URL` not updated | Set `WEBHOOK_URL=https://your-domain.com/` in `.env` |
| High memory usage | Default limits too high for your host | Lower `deploy.resources.limits.memory` in compose |

---

## Security Notes

- `.env` is **gitignored** — never commit real secrets
- `N8N_BLOCK_ENV_ACCESS_IN_NODE=true` — nodes can't read host env vars
- `N8N_RESTRICT_FILE_ACCESS_TO=/home/node/.n8n` — file operations sandboxed
- `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true` — strict file perms
- Task runners authenticate via shared `RUNNERS_AUTH_TOKEN`
- PostgreSQL uses a non-root user for n8n connections

---

## Upgrading n8n

1. Update `N8N_VERSION` in `.env`
2. `docker compose pull`
3. `docker compose up -d` (handles rolling restart with healthchecks)

> **Always backup `db_storage` before major version upgrades.**

---

## License

MIT — use freely, modify, distribute.