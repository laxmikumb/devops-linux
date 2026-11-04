#!/bin/bash
# health.sh: prints hostname, uptime, disk and memory usage

HOSTNAME=$(hostname)
UPTIME=$(uptime -p)
DISK=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
MEM=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')

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

for svc in nginx ssh; do
    if systemctl is-active --quiet "$svc"; then
        echo "$svc is running"
    else
        echo "$svc is DOWN"
    fi
done
