#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/docker/compose.spider.gpu.yml"
SERVICE="spider-gpu"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/spider_docker_gpu.sh up
  ./scripts/spider_docker_gpu.sh shell
  ./scripts/spider_docker_gpu.sh train
  ./scripts/spider_docker_gpu.sh run <command ...>
  ./scripts/spider_docker_gpu.sh down

Requirements:
  - Linux host
  - NVIDIA GPU
  - Docker Engine with NVIDIA Container Toolkit / `--gpus all` support

The `train` command runs:
  cd examples/spider && ~/.local/bin/uv run --no-sync python train_sql_agent.py qwen --active-agent write
EOF
}

ensure_service() {
  docker compose -f "$COMPOSE_FILE" up -d --build
}

command="${1:-up}"
shift || true

case "$command" in
  up)
    docker compose -f "$COMPOSE_FILE" up -d --build
    ;;
  shell)
    ensure_service
    docker compose -f "$COMPOSE_FILE" exec "$SERVICE" bash
    ;;
  train)
    ensure_service
    docker compose -f "$COMPOSE_FILE" exec "$SERVICE" bash -lc \
      'cd examples/spider && ~/.local/bin/uv run --no-sync python train_sql_agent.py qwen --active-agent write'
    ;;
  run)
    ensure_service
    if [[ "$#" -eq 0 ]]; then
      echo "Missing command after 'run'."
      usage
      exit 1
    fi
    docker compose -f "$COMPOSE_FILE" exec "$SERVICE" "$@"
    ;;
  down)
    docker compose -f "$COMPOSE_FILE" down --remove-orphans
    ;;
  *)
    usage
    exit 1
    ;;
esac
