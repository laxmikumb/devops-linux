#!/usr/bin/env bash
# Check every service and restart any that is not healthy. Log each result.
cd "$(dirname "$0")/.."
LOG=./health_check.log

for svc in db app nginx; do
  cid=$(docker compose ps -q "$svc")

  if [ -z "$cid" ]; then
    echo "$(date '+%F %T') $svc is not running, starting it" | tee -a "$LOG"
    docker compose up -d "$svc"
    continue
  fi

  status=$(docker inspect -f '{{.State.Health.Status}}' "$cid")

  if [ "$status" != "healthy" ]; then
    echo "$(date '+%F %T') $svc is $status, restarting it" | tee -a "$LOG"
    docker compose restart "$svc"
  else
    echo "$(date '+%F %T') $svc is healthy" | tee -a "$LOG"
  fi
done
