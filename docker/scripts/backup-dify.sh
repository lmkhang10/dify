#!/usr/bin/env bash
# backup-dify.sh — backup self-hosted Dify (Docker Compose)
#
# Covers:
#   - PostgreSQL logical dumps (dify + dify_plugin)
#   - Bind-mount volumes (uploads / knowledge files / Weaviate / plugins / redis / sandbox)
#   - docker/.env
#   - Optional: repo examples/ (portable DSL samples + knowledge markdown)
#   - Optional: Console API export of all apps → DSL YAML
#
# Knowledge bases = Postgres metadata + volumes/app/storage + Weaviate vectors.
# App DSL alone is NOT a full KB restore.
#
# Usage:
#   ./docker/scripts/backup-dify.sh
#   BACKUP_ROOT=~/dify-backups ./docker/scripts/backup-dify.sh
#   MODE=cold ./docker/scripts/backup-dify.sh
#   EXPORT_DSL=1 DIFY_EMAIL=a@b.c DIFY_PASSWORD='secret' ./docker/scripts/backup-dify.sh
#   EXPORT_DSL=1 DIFY_ACCESS_TOKEN='...' ./docker/scripts/backup-dify.sh
#
# Restore: ./docker/scripts/restore-dify.sh ~/dify-backups/<STAMP>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${DOCKER_DIR}/.." && pwd)"

COMPOSE_PROJECT="${COMPOSE_PROJECT:-dify}"
COMPOSE=(docker compose -p "${COMPOSE_PROJECT}" -f "${DOCKER_DIR}/docker-compose.yaml")
MODE="${MODE:-hot}" # hot | cold
EXPORT_DSL="${EXPORT_DSL:-0}"
INCLUDE_EXAMPLES="${INCLUDE_EXAMPLES:-1}"
INCLUDE_REDIS="${INCLUDE_REDIS:-1}"
DIFY_URL="${DIFY_URL:-http://localhost}"
BACKUP_ROOT="${BACKUP_ROOT:-${HOME}/dify-backups}"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="${BACKUP_ROOT}/${STAMP}"

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

load_dotenv_keys() {
  local env_file="$1"
  local line key val
  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ "${line}" =~ ^[[:space:]]*# ]] && continue
    [[ "${line}" =~ ^(DB_|REDIS_|DB_PLUGIN_|COMPOSE_PROFILES=) ]] || continue
    key="${line%%=*}"
    val="${line#*=}"
    # strip optional surrounding quotes
    val="${val%\"}"
    val="${val#\"}"
    val="${val%\'}"
    val="${val#\'}"
    printf -v "${key}" '%s' "${val}"
    export "${key}"
  done <"${env_file}"
}

load_env() {
  local env_file="${DOCKER_DIR}/.env"
  [[ -f "${env_file}" ]] || die "missing ${env_file}"
  load_dotenv_keys "${env_file}"
  DB_USERNAME="${DB_USERNAME:-postgres}"
  DB_PASSWORD="${DB_PASSWORD:-difyai123456}"
  DB_DATABASE="${DB_DATABASE:-dify}"
  DB_PLUGIN_DATABASE="${DB_PLUGIN_DATABASE:-dify_plugin}"
}

compose_ok() {
  "${COMPOSE[@]}" ps --status running --services 2>/dev/null | grep -qx 'db_postgres'
}

dump_postgres() {
  local dest="$1"
  mkdir -p "${dest}"
  log "pg_dump ${DB_DATABASE}"
  "${COMPOSE[@]}" exec -T -e "PGPASSWORD=${DB_PASSWORD}" db_postgres \
    pg_dump -U "${DB_USERNAME}" -d "${DB_DATABASE}" -F c \
    >"${dest}/${DB_DATABASE}.dump"

  if "${COMPOSE[@]}" exec -T -e "PGPASSWORD=${DB_PASSWORD}" db_postgres \
    psql -U "${DB_USERNAME}" -d postgres -tAc \
    "SELECT 1 FROM pg_database WHERE datname='${DB_PLUGIN_DATABASE}'" | grep -q 1; then
    log "pg_dump ${DB_PLUGIN_DATABASE}"
    "${COMPOSE[@]}" exec -T -e "PGPASSWORD=${DB_PASSWORD}" db_postgres \
      pg_dump -U "${DB_USERNAME}" -d "${DB_PLUGIN_DATABASE}" -F c \
      >"${dest}/${DB_PLUGIN_DATABASE}.dump"
  else
    log "skip ${DB_PLUGIN_DATABASE} (database not found)"
  fi
}

archive_volumes() {
  local dest="$1"
  local volumes_dir="${DOCKER_DIR}/volumes"
  [[ -d "${volumes_dir}" ]] || die "missing ${volumes_dir}"

  local excludes=()
  if [[ "${MODE}" == "hot" ]]; then
    excludes+=(--exclude='db/data')
    log "tar volumes (hot: exclude db/data — use pg_dump)"
  else
    log "tar volumes (cold: include db/data)"
  fi
  if [[ "${INCLUDE_REDIS}" != "1" ]]; then
    excludes+=(--exclude='redis/data')
  fi

  tar -C "${DOCKER_DIR}" -czf "${dest}/volumes.tgz" "${excludes[@]}" volumes
}

copy_env_and_meta() {
  local dest="$1"
  cp -a "${DOCKER_DIR}/.env" "${dest}/env"
  {
    echo "stamp=${STAMP}"
    echo "mode=${MODE}"
    echo "compose_project=${COMPOSE_PROJECT}"
    echo "compose_profiles=${COMPOSE_PROFILES:-}"
    echo "db_database=${DB_DATABASE}"
    echo "db_plugin_database=${DB_PLUGIN_DATABASE}"
    echo "host=$(hostname)"
    echo "dify_url=${DIFY_URL}"
    echo "created_at=$(date -Iseconds 2>/dev/null || date)"
  } >"${dest}/MANIFEST.txt"
}

copy_examples() {
  local dest="$1"
  local examples="${REPO_ROOT}/examples"
  if [[ "${INCLUDE_EXAMPLES}" != "1" || ! -d "${examples}" ]]; then
    return 0
  fi
  log "copy examples/ (portable DSL + knowledge markdown)"
  mkdir -p "${dest}/examples"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude='*.difypkg' --exclude='.DS_Store' "${examples}/" "${dest}/examples/"
  else
    cp -a "${examples}/." "${dest}/examples/"
    find "${dest}/examples" -name '*.difypkg' -delete 2>/dev/null || true
  fi
}

export_apps_dsl() {
  local dest="$1"
  need curl
  need python3
  mkdir -p "${dest}/dsl"

  if [[ -z "${DIFY_ACCESS_TOKEN:-}" && ( -z "${DIFY_EMAIL:-}" || -z "${DIFY_PASSWORD:-}" ) ]]; then
    log "EXPORT_DSL=1 but no credentials — skip (set DIFY_ACCESS_TOKEN or DIFY_EMAIL+DIFY_PASSWORD)"
    return 0
  fi

  log "export apps DSL via Console API"
  DIFY_URL="${DIFY_URL%/}" \
  DIFY_EMAIL="${DIFY_EMAIL:-}" \
  DIFY_PASSWORD="${DIFY_PASSWORD:-}" \
  DIFY_ACCESS_TOKEN="${DIFY_ACCESS_TOKEN:-}" \
  DSL_DIR="${dest}/dsl" \
  python3 - <<'PY'
import json, os, re, urllib.error, urllib.request
from pathlib import Path

base = os.environ["DIFY_URL"].rstrip("/")
out = Path(os.environ["DSL_DIR"])
token = os.environ.get("DIFY_ACCESS_TOKEN") or ""

def http_json(method, path, body=None, headers=None):
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(
        f"{base}{path}",
        data=data,
        method=method,
        headers={"Content-Type": "application/json", **(headers or {})},
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        return json.load(resp)

if not token:
    login = http_json(
        "POST",
        "/console/api/login",
        {"email": os.environ["DIFY_EMAIL"], "password": os.environ["DIFY_PASSWORD"], "remember_me": True},
    )
    token = ((login.get("data") or {}) if isinstance(login.get("data"), dict) else {}).get("access_token") or login.get("access_token") or ""
    if not token and isinstance(login.get("data"), dict):
        token = login["data"].get("access_token") or ""
    if not token:
        raise SystemExit(f"login failed: {login!r}"[:500])

auth = {"Authorization": f"Bearer {token}"}
apps = []
page = 1
while page <= 50:
    payload = http_json("GET", f"/console/api/apps?page={page}&limit=100", headers=auth)
    chunk = payload.get("data") or []
    if isinstance(chunk, dict):
        chunk = chunk.get("data") or []
    apps.extend([a for a in chunk if isinstance(a, dict) and a.get("id")])
    has_more = payload.get("has_more")
    if has_more is False:
        break
    if has_more is True:
        page += 1
        continue
    total = payload.get("total")
    limit = int(payload.get("limit") or 100)
    if total is not None:
        if page * limit >= int(total):
            break
        page += 1
        continue
    if len(chunk) < limit:
        break
    page += 1

(out / "_apps.json").write_text(json.dumps(apps, indent=2), encoding="utf-8")
lines = []
for app in apps:
    aid = str(app["id"])
    name = app.get("name") or aid
    safe = re.sub(r"[^\w\-]+", "_", str(name)).strip("_")[:80] or aid
    fname = f"{safe}__{aid}.yml"
    print(f"export {fname}", flush=True)
    try:
        exp = http_json("GET", f"/console/api/apps/{aid}/export?include_secret=false", headers=auth)
    except urllib.error.HTTPError as e:
        print(f"WARN skip {aid}: HTTP {e.code}", flush=True)
        continue
    dsl = exp.get("data")
    if not isinstance(dsl, str) or not dsl.strip():
        print(f"WARN skip {aid}: empty dsl", flush=True)
        continue
    (out / fname).write_text(dsl, encoding="utf-8")
    lines.append(f"{aid}\t{fname}")

(out / "_export_list.txt").write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
print(f"COUNT={len(lines)}", flush=True)
PY

  local count=0
  if [[ -f "${dest}/dsl/_export_list.txt" ]]; then
    count="$(grep -c . "${dest}/dsl/_export_list.txt" || true)"
  fi
  log "exported ${count} app DSL file(s)"
  echo "dsl_export_count=${count}" >>"${dest}/MANIFEST.txt"
}

write_readme() {
  cat >"$1/README.md" <<EOF
# Dify backup ${STAMP}

## Contents
- \`postgres/*.dump\` — pg_dump custom format (\`${DB_DATABASE}\`, \`${DB_PLUGIN_DATABASE}\`)
- \`volumes.tgz\` — docker/volumes (mode=${MODE})
- \`env\` — copy of docker/.env
- \`examples/\` — sample DSL / knowledge markdown (if present)
- \`dsl/\` — Console API app exports (if EXPORT_DSL=1)

## Mapping
| Piece | Covered by |
|---|---|
| Apps / workflows / agents / accounts / messages | postgres dump |
| Knowledge docs on disk | volumes/app/storage |
| Knowledge vectors | volumes/weaviate |
| Plugin installs | volumes/plugin_daemon + plugin DB dump |
| Secrets / profiles | env |
| Portable app YAML | dsl/ + examples/ |

LFMS MySQL (\`lfms-db\`) is outside this stack — backup separately.

## Restore
\`\`\`bash
./docker/scripts/restore-dify.sh ${OUT}
\`\`\`
EOF
}

main() {
  need docker
  need tar
  load_env

  mkdir -p "${OUT}/postgres"
  log "backup → ${OUT}"

  compose_ok || die "db_postgres is not running (project=${COMPOSE_PROJECT}). Start: cd docker && docker compose -p ${COMPOSE_PROJECT} up -d"

  if [[ "${MODE}" == "cold" ]]; then
    log "MODE=cold → stopping compose (keeps volumes)"
    "${COMPOSE[@]}" stop
    archive_volumes "${OUT}"
    log "starting compose again for dumps…"
    "${COMPOSE[@]}" start
    for _ in $(seq 1 60); do
      if compose_ok && "${COMPOSE[@]}" exec -T db_postgres pg_isready -U "${DB_USERNAME}" >/dev/null 2>&1; then
        break
      fi
      sleep 2
    done
  fi

  dump_postgres "${OUT}/postgres"
  if [[ "${MODE}" != "cold" ]]; then
    archive_volumes "${OUT}"
  fi

  copy_env_and_meta "${OUT}"
  copy_examples "${OUT}"

  if [[ "${EXPORT_DSL}" == "1" ]]; then
    export_apps_dsl "${OUT}" || log "DSL export failed (volumes+DB backup still OK)"
  fi

  write_readme "${OUT}"

  (
    cd "${OUT}"
    find . -type f ! -name 'SHA256SUMS' -print0 | sort -z | xargs -0 shasum -a 256 >SHA256SUMS
  )

  local size
  size="$(du -sh "${OUT}" | awk '{print $1}')"
  log "done: ${OUT} (${size})"
  log "restore: ${SCRIPT_DIR}/restore-dify.sh ${OUT}"
}

main "$@"
