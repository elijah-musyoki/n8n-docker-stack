# Agent Instructions

## Package Manager
N/A — Docker Compose project.

## Commands
| Task | Command |
|------|---------|
| Start | `docker compose up -d` |
| Stop | `docker compose down` |
| Stop (preserve volumes) | `docker compose stop` |
| Full cleanup (data loss) | `docker compose down -v` |
| Pull images | `docker compose pull` |
| Logs | `docker compose logs -f` |

## External References
| Need | File |
|------|------|
| Config | `.env.example` |
| Architecture | `README.md` |
| Services | `docker-compose.yml` |

## Key Conventions
- Secrets in `.env` — gitignored, never commit.
- First deploy: `cp .env.example .env`, generate secrets with `openssl rand -hex 32`.
- DB init: `init-data.sh` runs on first Postgres startup. Re-run: `docker compose down -v`.
- Update n8n: change `N8N_VERSION` in `.env`, then `docker compose pull && docker compose up -d`.
- OTLP traces: n8n → host Alloy (host.docker.internal:4318) → Grafana Cloud Tempo.

## Commit Attribution
```
Co-Authored-By: opencode <support@opencode.ai>
```
