#!/bin/bash
# health.sh: prints hostname, uptime, disk and memory usage

HOSTNAME=$(hostname)
UPTIME=$(uptime -p)
DISK=$(df -h | grep -n 5)
MEM=$(free -h | awk '{print $5}' | grep -n 5)

echo "=== Health report: $(date) ==="
echo "Hostname : $HOSTNAME"
echo "Uptime   : $UPTIME"
echo "Disk used: ${DISK}%"
echo "Mem used : ${MEM}%"

if [ "$DISK" -gt 80 ]; then
    echo "ALERT: disk usage above 80%"
else
    echo "Disk OK"
fi
