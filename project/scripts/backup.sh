#!/bin/bash
# backup.sh: archives the site and the Nginx config into a timestamped .tar.gz
# and keeps only the newest 7 backups.

BACKUP_DIR=/var/backups/shoplite
SITE_DIR=/var/www/shoplite
NGINX_CONF=/etc/nginx/sites-available/shoplite
KEEP=7

mkdir -p "$BACKUP_DIR"
TS=$(date +%Y-%m-%d_%H%M%S)
FILE="$BACKUP_DIR/shoplite_$TS.tar.gz"

# Create the archive (stored outside the folder being archived)
if tar -czf "$FILE" "$SITE_DIR" "$NGINX_CONF"; then
    echo "$(date '+%F %T') backup created: $FILE"
else
    echo "$(date '+%F %T') backup FAILED" >&2
    rm -f "$FILE"      # remove the broken partial archive
    exit 1
fi

# Retention: list newest first, skip the first 7, delete the rest
ls -1t "$BACKUP_DIR"/shoplite_*.tar.gz | tail -n +$((KEEP + 1)) | xargs -r rm -f --
exit 0
