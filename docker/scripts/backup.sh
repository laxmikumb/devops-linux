#!/usr/bin/env bash
# Dump the ShopLite database into a timestamped file and keep the last 7.
set -euo pipefail

# Always work from the docker/ folder, wherever the script is called from
cd "$(dirname "$0")/.."

# Load POSTGRES_USER and POSTGRES_DB from .env
set -a
source .env
set +a

BACKUP_DIR=./backups
mkdir -p "$BACKUP_DIR"
FILE="$BACKUP_DIR/shoplite_$(date +%Y%m%d_%H%M%S).sql"

# -T: no terminal, so the output can be redirected to a file
docker compose exec -T db pg_dump -U "$POSTGRES_USER" --clean --if-exists "$POSTGRES_DB" > "$FILE"

# Keep only the newest 7 backups
ls -1t "$BACKUP_DIR"/shoplite_*.sql | tail -n +8 | xargs -r rm --

echo "$(date '+%F %T') backup saved: $FILE"
