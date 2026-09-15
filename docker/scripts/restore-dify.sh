#!/usr/bin/env bash
# restore-dify.sh — restore a backup created by backup-dify.sh
#
# Usage:
#   ./docker/scripts/restore-dify.sh ~/dify-backups/20260914_160000
#
# WARNING: overwrites docker/volumes and restores Postgres databases.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_PROJECT="${COMPOSE_PROJECT:-dify}"
COMPOSE=(docker compose -p "${COMPOSE_PROJECT}" -f "${DOCKER_DIR}/docker-compose.yaml")

BACKUP_DIR="${1:-}"
[[ -n "${BACKUP_DIR}" && -d "${BACKUP_DIR}" ]] || {
  echo "Usage: $0 /path/to/backup/STAMP" >&2
  exit 1
}
BACKUP_DIR="$(cd "${BACKUP_DIR}" && pwd)"

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

load_dotenv_keys() {
  local env_file="$1"
  local line key val
  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ "${line}" =~ ^[[:space:]]*# ]] && continue
    [[ "${line}" =~ ^(DB_|REDIS_|DB_PLUGIN_|COMPOSE_PROFILES=) ]] || continue
    key="${line%%=*}"
    val="${line#*=}"
    val="${val%\"}"
    val="${val#\"}"
    val="${val%\'}"
    val="${val#\'}"
    printf -v "${key}" '%s' "${val}"
    export "${key}"
  done <"${env_file}"
}

[[ -f "${BACKUP_DIR}/volumes.tgz" ]] || die "missing volumes.tgz"

if [[ -f "${BACKUP_DIR}/env" ]]; then
  load_dotenv_keys "${BACKUP_DIR}/env"
fi
DB_USERNAME="${DB_USERNAME:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-difyai123456}"
DB_DATABASE="${DB_DATABASE:-dify}"
DB_PLUGIN_DATABASE="${DB_PLUGIN_DATABASE:-dify_plugin}"

DUMP_MAIN="${BACKUP_DIR}/postgres/${DB_DATABASE}.dump"
[[ -f "${DUMP_MAIN}" ]] || DUMP_MAIN="${BACKUP_DIR}/postgres/dify.dump"
[[ -f "${DUMP_MAIN}" ]] || die "missing postgres dump for ${DB_DATABASE}"
DUMP_PLUGIN="${BACKUP_DIR}/postgres/${DB_PLUGIN_DATABASE}.dump"

log "stop stack"
"${COMPOSE[@]}" down

log "restore volumes"
rm -rf "${DOCKER_DIR}/volumes"
tar -C "${DOCKER_DIR}" -xzf "${BACKUP_DIR}/volumes.tgz"

if [[ -f "${BACKUP_DIR}/env" ]]; then
  log "restore .env (from backup/env)"
  cp -a "${BACKUP_DIR}/env" "${DOCKER_DIR}/.env"
fi

log "start postgres (+ redis)"
"${COMPOSE[@]}" up -d db_postgres redis
for _ in $(seq 1 90); do
  if "${COMPOSE[@]}" exec -T db_postgres pg_isready -U "${DB_USERNAME}" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

log "restore ${DB_DATABASE}"
# pg_restore often exits 1 on benign warnings when using --clean
set +e
"${COMPOSE[@]}" exec -T -e "PGPASSWORD=${DB_PASSWORD}" db_postgres \
  pg_restore -U "${DB_USERNAME}" -d "${DB_DATABASE}" --clean --if-exists \
  <"${DUMP_MAIN}"
set -e

if [[ -f "${DUMP_PLUGIN}" ]]; then
  log "ensure ${DB_PLUGIN_DATABASE} exists"
  if ! "${COMPOSE[@]}" exec -T -e "PGPASSWORD=${DB_PASSWORD}" db_postgres \
    psql -U "${DB_USERNAME}" -d postgres -tAc \
    "SELECT 1 FROM pg_database WHERE datname='${DB_PLUGIN_DATABASE}'" | grep -q 1; then
    "${COMPOSE[@]}" exec -T -e "PGPASSWORD=${DB_PASSWORD}" db_postgres \
      psql -U "${DB_USERNAME}" -d postgres -c "CREATE DATABASE ${DB_PLUGIN_DATABASE};"
  fi
  log "restore ${DB_PLUGIN_DATABASE}"
  set +e
  "${COMPOSE[@]}" exec -T -e "PGPASSWORD=${DB_PASSWORD}" db_postgres \
    pg_restore -U "${DB_USERNAME}" -d "${DB_PLUGIN_DATABASE}" --clean --if-exists \
    <"${DUMP_PLUGIN}"
  set -e
fi

log "start full stack"
"${COMPOSE[@]}" up -d

log "done. Open http://localhost"
log "dsl/ in the backup is portable YAML — Studio → Import DSL if needed."
if [[ -d "${BACKUP_DIR}/dsl" ]]; then
  log "DSL files: ${BACKUP_DIR}/dsl"
fi
