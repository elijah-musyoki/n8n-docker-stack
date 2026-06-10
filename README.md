# n8n with PostgreSQL, Redis, and Worker

Starts n8n with PostgreSQL as database, Redis for queue management, and a Worker as a separate container. Task runner sidecar containers are included for executing Code nodes (JavaScript/Python), as required by n8n 2.0+.

## Start

Copy `.env.example` to `.env` and fill in your values before starting the stack:

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
- `RUNNERS_AUTH_TOKEN` is a shared secret used for authentication between n8n and the task runner containers. Generate a secure random value for production use.
