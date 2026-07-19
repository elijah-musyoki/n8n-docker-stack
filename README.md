# n8n with PostgreSQL, Redis, workers, runners, and Alloy

A Docker Compose stack for n8n.
It includes PostgreSQL, Redis, a main n8n service, a worker, two task runners, and Alloy on the host.

- PostgreSQL stores workflow and execution data.
- Redis handles the queue.
- n8n serves the UI and API.
- n8n-worker runs queued jobs.
- n8n-runner handles Code node tasks.
- n8n-worker-runner handles task runner jobs for the worker.
- Alloy receives OTLP traces and forwards them to Grafana Cloud Tempo.

---

## Layout

```
n8n main        → Web UI and API on port 5678
PostgreSQL      → Database
Redis           → Queue
n8n-worker      → Worker
n8n-runner      → Task runner
n8n-worker-runner → Task runner for the worker
Alloy           → OTLP receiver on the host
```

All services use the internal `n8n-net` network.

---

## Quick start

```bash
./bootstrap.sh
```

Open:
- `http://localhost:5678`

---

## Local stack examples

You can run three local stacks from the same compose file.
Each stack needs its own project name and env file.

| Stack | Project name | Host port | Env file |
|---|---|---:|---|
| Dev | `n8n-dev` | `5678` | `.env` |
| Local staging | `n8n-staging` | `5679` | `.env.local-staging` |
| Local prod | `n8n-prod` | `5680` | `.env.local-prod` |

Start them like this:

```bash
docker compose -p n8n-dev up -d
docker compose -p n8n-staging --env-file .env.local-staging up -d
docker compose -p n8n-prod --env-file .env.local-prod up -d
```

Copy the example files first:

```bash
cp .env.local-staging.example .env.local-staging
cp .env.local-prod.example .env.local-prod
```

Set `N8N_HOST_PORT` and `N8N_WEBHOOK_URL` in each file.
Keep `N8N_PORT=5678` inside every stack.

---

## Stop

```bash
docker compose stop
```

Remove containers and networks:

```bash
docker compose down
```

Remove everything, including volumes:

```bash
docker compose down -v
```

---

## Configure

Edit `.env`.
Copy it from `.env.example`.

Required values:

| Variable | Meaning |
|---|---|
| `N8N_VERSION` | n8n image tag |
| `POSTGRES_VERSION` | PostgreSQL image tag |
| `REDIS_VERSION` | Redis image tag |
| `POSTGRES_USER` | Postgres user |
| `POSTGRES_PASSWORD` | Postgres password |
| `POSTGRES_DB` | Database name |
| `POSTGRES_NON_ROOT_USER` | App DB user |
| `POSTGRES_NON_ROOT_PASSWORD` | App DB password |
| `ENCRYPTION_KEY` | 32 byte hex key |
| `RUNNERS_AUTH_TOKEN` | Shared runner token |
| `REDIS_PASSWORD` | Redis password |
| `N8N_OTEL_TRACES_SAMPLE_RATE` | Trace sample rate |
| `N8N_ENDPOINT_HEALTH` | Health path |
| `N8N_PORT` | Container port |
| `N8N_HOST_PORT` | Host port |
| `N8N_WEBHOOK_URL` | Public webhook URL |
| `GRAFANA_CLOUD_TRACES_INSTANCE_ID` | Grafana Cloud traces ID |
| `GRAFANA_CLOUD_API_KEY` | Grafana Cloud API key |

Other values:
- `N8N_HOST`
- `N8N_PROTOCOL`
- `GENERIC_TIMEZONE`
- `TZ`
- `N8N_OTEL_TRACES_PRODUCTION_ONLY`
- `REDIS_MAXMEMORY`
- `REDIS_MAXMEMORY_POLICY`
- `QUEUE_BULL_REDIS_PORT`

---

## Secrets

Generate or refresh `.env` with:

```bash
./generate-secrets.py
```
If you need the values by hand:

```bash
openssl rand -hex 32   # ENCRYPTION_KEY
openssl rand -hex 32   # RUNNERS_AUTH_TOKEN
openssl rand -hex 32   # REDIS_PASSWORD
openssl rand -hex 16   # POSTGRES_PASSWORD / POSTGRES_NON_ROOT_PASSWORD
```

---

## Database init

`init-data.sh` runs on the first PostgreSQL start.
It creates the non-root database user.
It grants the rights n8n needs for its schema.

If you change `POSTGRES_NON_ROOT_USER` or `POSTGRES_NON_ROOT_PASSWORD` later, do one of these:
- run the SQL by hand
- wipe the `db_storage` volume with `docker compose down -v`

---

## Observability

| Feature | Config | Notes |
|---|---|---|
| OpenTelemetry traces | `N8N_OTEL_ENABLED=true` | Sends traces to `http://host.docker.internal:4318` |
| Prometheus metrics | `N8N_METRICS=true` | Read at `http://localhost:5678/metrics` |
| JSON logs | `N8N_LOG_FORMAT=json` | Good for log collectors |
| Queue metrics | `N8N_METRICS_INCLUDE_QUEUE_METRICS=true` | Shows queue depth and latency |

---

## Resources

The compose file sets CPU and memory limits.
If your host is small, lower them in `docker-compose.yml`.

| Service | CPU | Memory |
|---|---:|---:|
| n8n main | 2 cores | 1 GB |
| n8n-worker | 4 cores | 2 GB |
| n8n-runner | 1 core | 512 MB |
| n8n-worker-runner | 1 core | 512 MB |
| PostgreSQL | 2 cores | 1 GB |
| Redis | 1 core | 256 MB |

---

## Persistence

Named Docker volumes survive `docker compose down`.

| Volume | Service | Use |
|---|---|---|
| `db_storage` | postgres | Database data |
| `n8n_storage` | n8n and n8n-worker | n8n state and custom nodes |
| `redis_storage` | redis | Queue data |

Backup:

```bash
docker run --rm -v db_storage:/data -v $(pwd):/backup alpine tar czf /backup/db_backup_$(date +%F).tar.gz -C /data .
```

---

## Common issues

| Symptom | Cause | Fix |
|---|---|---|
| n8n healthcheck fails | Alloy is not running or not reachable | Start Alloy and check `http://host.docker.internal:4318` |
| `POSTGRES_NON_ROOT_USER` is missing | `init-data.sh` did not run | Run `docker compose down -v && docker compose up -d` |
| Task runners do not connect | `RUNNERS_AUTH_TOKEN` mismatch | Use the same value in every env file |
| Webhook URLs show `localhost` | `N8N_WEBHOOK_URL` is not set for that stack | Set the correct public URL in `.env` |
| Memory use is high | Limits are too large for the host | Lower `deploy.resources.limits` |

---

## Security notes

- `.env` is gitignored.
- Do not commit real secrets.
- `N8N_BLOCK_ENV_ACCESS_IN_NODE=true` blocks host env access.
- `N8N_RESTRICT_FILE_ACCESS_TO=/home/node/.n8n` limits file access.
- `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true` keeps strict file perms.
- Task runners use `RUNNERS_AUTH_TOKEN`.
- `host.docker.internal` lets containers reach host Alloy.
- PostgreSQL uses a non-root user for n8n.

---

## Upgrade

1. Change `N8N_VERSION` in `.env`.
2. Run `docker compose pull`.
3. Run `docker compose up -d`.

Back up `db_storage` before a major upgrade.

---

## License

MIT. Use it, change it, share it.
