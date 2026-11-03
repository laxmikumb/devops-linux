#!/bin/bash
# deploy.sh: pull the latest site from GitHub, publish it, test Nginx config,
# reload Nginx. If "nginx -t" fails, roll back to the previous version.

REPO_DIR=${REPO_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}
SITE_DIR=/var/www/shoplite
CONF_DEST=/etc/nginx/sites-available/shoplite
SNAP=$(mktemp -d /tmp/shoplite_prev.XXXXXX)
OWNER=$(id deploy >/dev/null 2>&1 && echo deploy || echo root)

log() { echo "$(date '+%F %T') $1"; }

# 1. Pull latest code (set SKIP_PULL=1 to test with local changes)
if [ "${SKIP_PULL:-0}" != "1" ]; then
    log "pulling latest from GitHub"
    git -C "$REPO_DIR" pull --ff-only || { log "git pull failed"; exit 1; }
fi

# 2. Snapshot the current live version (for rollback)
mkdir -p "$SITE_DIR"
cp -a "$SITE_DIR/." "$SNAP/site/" 2>/dev/null || { mkdir -p "$SNAP/site"; cp -a "$SITE_DIR/." "$SNAP/site/"; }
cp -a "$CONF_DEST" "$SNAP/shoplite.conf" 2>/dev/null

# 3. Publish new site files and Nginx config
cp -a "$REPO_DIR/project/site/." "$SITE_DIR/"
cp "$REPO_DIR/project/configs/nginx-shoplite.conf" "$CONF_DEST"
ln -sf "$CONF_DEST" /etc/nginx/sites-enabled/shoplite
chown -R "$OWNER":www-data "$SITE_DIR"
find "$SITE_DIR" -type d -exec chmod 750 {} \;
find "$SITE_DIR" -type f -exec chmod 640 {} \;

# 4. Test config; roll back on failure
if nginx -t; then
    systemctl reload nginx
    log "deploy OK, nginx reloaded"
    rm -rf "$SNAP"
    exit 0
else
    log "nginx -t FAILED, rolling back"
    [ -f "$SNAP/shoplite.conf" ] && cp -a "$SNAP/shoplite.conf" "$CONF_DEST"
    cp -a "$SNAP/site/." "$SITE_DIR/"
    nginx -t && systemctl reload nginx
    log "rollback complete"
    rm -rf "$SNAP"
    exit 1
fi
