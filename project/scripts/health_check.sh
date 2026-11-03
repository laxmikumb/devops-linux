#!/bin/bash
# health_check.sh: checks CPU, memory, disk and Nginx.
# Restarts Nginx if it is down. Every result is written to the log.

LOG_DIR=/var/log/shoplite
LOG_FILE="$LOG_DIR/health.log"
DISK_THRESHOLD=${DISK_THRESHOLD:-80}   # can be overridden for testing
CPU_THRESHOLD=${CPU_THRESHOLD:-80}
MEM_THRESHOLD=${MEM_THRESHOLD:-80}

mkdir -p "$LOG_DIR"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

CPU=$(vmstat 1 2 | tail -1 | awk '{print 100-$15}')
MEM=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
DISK=$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')

log "INFO  cpu=${CPU}% mem=${MEM}% disk=${DISK}%"

[ "$CPU"  -gt "$CPU_THRESHOLD" ]  && log "ALERT cpu above ${CPU_THRESHOLD}% (${CPU}%)"
[ "$MEM"  -gt "$MEM_THRESHOLD" ]  && log "ALERT memory above ${MEM_THRESHOLD}% (${MEM}%)"
[ "$DISK" -gt "$DISK_THRESHOLD" ] && log "ALERT disk above ${DISK_THRESHOLD}% (${DISK}%)"

if systemctl is-active --quiet nginx; then
    log "OK    nginx is running"
else
    log "ALERT nginx is DOWN, restarting"
    systemctl restart nginx
    sleep 2
    if systemctl is-active --quiet nginx; then
        log "FIXED nginx restarted successfully"
    else
        log "FAIL  nginx could not be restarted"
        exit 1
    fi
fi
exit 0
