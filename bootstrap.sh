#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

umask 077

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Error: required command not found: %s\n' "$1" >&2
    exit 1
  }
}

compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
  else
    printf '%s\n' 'Error: Docker Compose is not installed.' >&2
    exit 1
  fi
}

require_command docker

docker info >/dev/null 2>&1 || {
  printf '%s\n' 'Error: Docker daemon is not running.' >&2
  exit 1
}

if [[ ! -f .env ]]; then
  "$SCRIPT_DIR/generate-secrets.py"
else
  echo ".env already exists; leaving it unchanged"
fi

compose config >/dev/null
compose up -d

echo "n8n is starting at http://localhost:5678"
