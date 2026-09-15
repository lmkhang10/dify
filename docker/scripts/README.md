# Dify Docker backup / restore

## Backup (recommended daily)

```bash
cd docker
./scripts/backup-dify.sh
```

Default output: `~/dify-backups/<timestamp>/` (~100MB+ depending on knowledge/vector data).

Includes:

| Artifact | What |
|---|---|
| `postgres/dify.dump` | Apps, workflows, agents, accounts, messages, KB metadata |
| `postgres/dify_plugin.dump` | Plugin daemon DB |
| `volumes.tgz` | Uploads, knowledge files, Weaviate, plugins, redis, sandbox |
| `env` | `docker/.env` |
| `examples/` | Portable sample DSL / knowledge markdown from repo |

### Options

```bash
# Stop stack first (also archives live Postgres data dir)
MODE=cold ./scripts/backup-dify.sh

# Also export every Studio app as YAML (needs login)
EXPORT_DSL=1 DIFY_EMAIL=you@example.com DIFY_PASSWORD='...' ./scripts/backup-dify.sh

# Or reuse a console access token
EXPORT_DSL=1 DIFY_ACCESS_TOKEN='...' ./scripts/backup-dify.sh

BACKUP_ROOT=/mnt/backups ./scripts/backup-dify.sh
```

Hot mode (default) excludes `volumes/db/data` and relies on `pg_dump` (safer while Postgres is running).

## Restore

```bash
./scripts/restore-dify.sh ~/dify-backups/20260914_160701
```

Overwrites `docker/volumes` and restores Postgres. DSL files under `dsl/` are **not** auto-imported — use Studio → Import DSL.

## Not included

- External DB such as LFMS MySQL (`lfms-db`) — backup that stack separately.
- LLM provider secrets that live only in cloud consoles (API keys in Dify are in Postgres / `.env`).
