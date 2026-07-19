# Agent Instructions

## Package manager
None. This project uses Docker Compose.

## Commands

| Task | Command |
|---|---|
| Start | `docker compose up -d` |
| Stop | `docker compose down` |
| Stop and keep volumes | `docker compose stop` |
| Remove everything | `docker compose down -v` |
| Pull images | `docker compose pull` |
| Logs | `docker compose logs -f` |

## Key files

| Need | File |
|---|---|
| Config | `.env.example` |
| Overview | `README.md` |
| Services | `docker-compose.yml` |
| Secrets | `generate-secrets.py` |
| DB init | `init-data.sh` |

## Key rules

- Keep secrets in `.env`.
- Do not commit `.env`.
- Use `uv run generate-secrets.py` on first run.
- `generate-secrets.py` writes `.env` in the repo root.
- `init-data.sh` runs on the first Postgres start.
- If the DB user changes later, run the SQL again or wipe `db_storage`.
- Update n8n by changing `N8N_VERSION` in `.env`.
- Then run `docker compose pull && docker compose up -d`.
- If n8n warns about webhook URLs, check the runtime logs for the version in use.
- OTLP traces go to host Alloy at `host.docker.internal:4318`.

## Commit attribution

```
Co-Authored-By: opencode <support@opencode.ai>
```
