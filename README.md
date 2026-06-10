# n8n with PostgreSQL, Redis, Worker, and Task Runners

Starts n8n with PostgreSQL as the database, Redis for queue management, a separate worker container, and task runner sidecars for executing Code nodes (JavaScript/Python), as required by n8n 2.0+.

## Start

Copy `.env.example` to `.env`, fill in your values, then start the stack:

```bash
cp .env.example .env
docker compose up -d
```

## Stop

```bash
docker compose stop
```

## Configuration

The `.env` file controls the image versions and credentials for the stack.

- `N8N_VERSION`, `POSTGRES_VERSION`, and `REDIS_VERSION` pin container versions.
- `POSTGRES_USER`, `POSTGRES_PASSWORD`, and related values configure PostgreSQL.
- `ENCRYPTION_KEY` should be a secure 32-byte hex value generated with `openssl rand -hex 32`.
- `N8N_OTEL_TRACES_SAMPLE_RATE` controls trace sampling. `0.1` keeps roughly 10% of traces.
- `N8N_ENDPOINT_HEALTH` keeps the compose healthchecks aligned with the current n8n health endpoint path.
- `WEBHOOK_URL` points at the local instance for now and should be updated when you add a public hostname.
- `RUNNERS_AUTH_TOKEN` is a shared secret used for authentication between n8n and the task runner containers. Generate a secure random value for production use.
