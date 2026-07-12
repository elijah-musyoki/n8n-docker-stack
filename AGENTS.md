# Agent Instructions

## Package Manager
N/A — this is a Docker Compose project.

## Commands
| Task | Command |
|------|---------|
| Start stack | `docker compose up -d` |
| Stop stack | `docker compose down` |
| Stop (preserve volumes) | `docker compose stop` |
| Full cleanup (data loss) | `docker compose down -v` |
| Pull latest images | `docker compose pull` |
| View logs | `docker compose logs -f` |

## External References
| Need | File |
|------|------|
| Setup & configuration | `.env.example` |
| Architecture | `README.md` |
| Service definitions | `docker-compose.yml` |

## Key Conventions
- Secrets go in `.env` — it is **gitignored**; never commit real secrets.
- First deploy: copy `.env.example` to `.env` and generate secure secrets with `openssl rand -hex 32`.
- DB init: `init-data.sh` runs automatically on first PostgreSQL startup to create the non-root DB user. To re-run, wipe volumes (`docker compose down -v`).
- Update n8n version by changing `N8N_VERSION` in `.env`, then `docker compose pull && docker compose up -d`.
- OTLP traces flow: n8n → Alloy sidecar (alloy:4318) → Grafana Cloud Tempo.

## Commit Attribution
AI commits MUST include:
```
Co-Authored-By: opencode <support@opencode.ai>
```
