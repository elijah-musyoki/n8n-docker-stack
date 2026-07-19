# n8n with PostgreSQL, Redis, workers, runners, and host Alloy

This repo runs n8n on one host. It uses PostgreSQL for data, Redis for the queue, a main n8n service, one worker, two task runner services, and Alloy on the host for traces.

## Start

1. Run `./bootstrap.sh`.
2. Open `http://localhost:5678`.

## Local stacks

You can run three local stacks from one compose file. Each stack needs its own project name and env file.

| Name | Project | Port | Env file |
|---|---|---:|---|
| Dev | `n8n-dev` | `5678` | `.env` |
| Local stage | `n8n-stage` | `5679` | `.env.local-staging` |
| Local prod | `n8n-prod` | `5680` | `.env.local-prod` |

Run them with:

```bash
docker compose -p n8n-dev up -d
docker compose -p n8n-stage --env-file .env.local-staging up -d
docker compose -p n8n-prod --env-file .env.local-prod up -d
```

Copy the example files first.

```bash
cp .env.local-staging.example .env.local-staging
cp .env.local-prod.example .env.local-prod
```

Set `N8N_HOST_PORT` and `N8N_WEBHOOK_URL` in each file. Keep `N8N_PORT=5678`.

## Stop

1. `docker compose stop`
2. `docker compose down`
3. `docker compose down -v`

## Settings

Edit `.env`. Copy it from `.env.example`.

| Value | Meaning |
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

| Value | Meaning |
|---|---|
| `N8N_HOST` | Host name |
| `N8N_PROTOCOL` | Protocol |
| `GENERIC_TIMEZONE` | Main time zone |
| `TZ` | Container time zone |
| `N8N_OTEL_TRACES_PRODUCTION_ONLY` | Trace mode |
| `REDIS_MAXMEMORY` | Redis memory limit |
| `REDIS_MAXMEMORY_POLICY` | Redis memory policy |
| `QUEUE_BULL_REDIS_PORT` | Redis port |

## Secrets

Run `./generate-secrets.py` to create or refresh `.env`.

If you need the values by hand, use:

```bash
openssl rand -hex 32   # ENCRYPTION_KEY
openssl rand -hex 32   # RUNNERS_AUTH_TOKEN
openssl rand -hex 32   # REDIS_PASSWORD
openssl rand -hex 16   # POSTGRES_PASSWORD / POSTGRES_NON_ROOT_PASSWORD
```

## Database init

`init-data.sh` runs on the first PostgreSQL start. It creates the non root database user. It grants the rights n8n needs for its schema.

If you change `POSTGRES_NON_ROOT_USER` or `POSTGRES_NON_ROOT_PASSWORD` later, do one of these:

1. Run the SQL by hand.
2. Wipe the `db_storage` volume with `docker compose down -v`.

## Logs and metrics

| Feature | Config | Notes |
|---|---|---|
| OpenTelemetry traces | `N8N_OTEL_ENABLED=true` | Sends traces to `http://host.docker.internal:4318` |
| Prometheus metrics | `N8N_METRICS=true` | Read at `http://localhost:5678/metrics` |
| JSON logs | `N8N_LOG_FORMAT=json` | Good for log collectors |
| Queue metrics | `N8N_METRICS_INCLUDE_QUEUE_METRICS=true` | Shows queue depth and latency |

## Limits

The compose file sets CPU and memory limits. Lower them in `docker-compose.yml` if the host is small.

| Service | CPU | Memory |
|---|---:|---:|
| n8n main | 2 cores | 1 GB |
| n8n-worker | 4 cores | 2 GB |
| n8n-runner | 1 core | 512 MB |
| n8n-worker-runner | 1 core | 512 MB |
| PostgreSQL | 2 cores | 1 GB |
| Redis | 1 core | 256 MB |

## Storage

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

## Problems

| Symptom | Cause | Fix |
|---|---|---|
| n8n healthcheck fails | Alloy is not running or not reachable | Start Alloy and check `http://host.docker.internal:4318` |
| `POSTGRES_NON_ROOT_USER` is missing | `init-data.sh` did not run | Run `docker compose down -v && docker compose up -d` |
| Task runners do not connect | `RUNNERS_AUTH_TOKEN` mismatch | Use the same value in every env file |
| Webhook URLs show `localhost` | `N8N_WEBHOOK_URL` is not set for that stack | Set the correct public URL in `.env` |
| Memory use is high | Limits are too large for the host | Lower `deploy.resources.limits` |

## Security

- `.env` is gitignored.
- Do not commit real secrets.
- `N8N_BLOCK_ENV_ACCESS_IN_NODE=true` blocks host env access.
- `N8N_RESTRICT_FILE_ACCESS_TO=/home/node/.n8n` limits file access.
- `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true` keeps strict file perms.
- Task runners use `RUNNERS_AUTH_TOKEN`.
- `host.docker.internal` lets containers reach host Alloy.
- PostgreSQL uses a non root user for n8n.

## Update

1. Change `N8N_VERSION` in `.env`.
2. Run `docker compose pull`.
3. Run `docker compose up -d`.

Back up `db_storage` before a major update.

## License

MIT. Use it, change it, share it.
