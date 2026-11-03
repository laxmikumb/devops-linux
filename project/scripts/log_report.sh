#!/bin/bash
# log_report.sh: summary of the Nginx access log.
# Prints total requests, top 5 IPs, top 5 pages, and count of 4xx/5xx errors.

LOG=${1:-/var/log/nginx/access.log}

if [ ! -r "$LOG" ]; then
    echo "Cannot read $LOG" >&2
    exit 1
fi

echo "=== ShopLite access report: $(date '+%F %T') ==="
echo "Log file: $LOG"
echo
echo "Total requests: $(wc -l < "$LOG")"
echo
echo "Top 5 IPs:"
awk '{print $1}' "$LOG" | sort | uniq -c | sort -nr | head -5
echo
echo "Top 5 pages:"
awk '{print $7}' "$LOG" | sort | uniq -c | sort -nr | head -5
echo
echo "4xx errors: $(awk '$9 ~ /^4/' "$LOG" | wc -l)"
echo "5xx errors: $(awk '$9 ~ /^5/' "$LOG" | wc -l)"
exit 0
