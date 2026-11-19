# ShopLite on Docker

A small three-tier shop: **nginx** serves the web page and proxies `/api/` to a **Flask** app, which reads products from **PostgreSQL**. Everything runs with one Compose file.

## Architecture
- `nginx` is the only service that publishes a port (host `8088` to container `80`).
- `app` (Flask + gunicorn) sits on both networks.
- `db` (Postgres 16) sits only on the backend network, so nginx cannot reach it directly.
- Two networks: `frontend` (nginx and app) and `backend` (app and db).
- Data lives in the named volume `pgdata`.

## Prerequisites
- Docker Engine and the Docker Compose plugin
- Port 8088 free on the host (8080 is used by Jenkins on my machine, which is why this isn't 8080)

## Run it
```bash
cd docker
cp .env.example .env        # then edit the password in .env
docker compose up -d
docker compose ps           # wait until all three show (healthy)
```

Open:
- Site: http://localhost:8088
- Health: http://localhost:8088/api/health
- Products: http://localhost:8088/api/products

## Backup and restore
```bash
./scripts/backup.sh                                   # writes backups/shoplite_<timestamp>.sql, keeps the newest 7
LATEST=$(ls -t backups/*.sql | head -1)
docker compose exec -T db psql -U shop -d shoplite < "$LATEST"
```
Replace `shop` and `shoplite` with the values from your `.env` if you changed them.

## Health check
```bash
./scripts/health_check.sh   # starts missing containers, restarts unhealthy ones, logs to health_check.log
```
It can be run from cron to check the stack regularly.

## Stop
```bash
docker compose down         # keeps the data
docker compose down -v      # also deletes the database volume. Use with care.
```

## Troubleshooting
- **502 Bad Gateway on /api/**: the app container is down or still starting. Run `docker compose ps` and `docker compose logs app`.
- **Port already in use**: change the left side of `8088:80` in `compose.yaml`.
- **Changed init.sql but nothing changed**: Postgres only runs init scripts on an empty data volume. Use `docker compose down -v` to start fresh (this deletes the data).
- **`no configuration file provided`**: run the command from the `docker/` folder.

## Images
- `laxmi707/shoplite-nginx:v1.0`
- `laxmi707/shoplite-app:v1.0`

## Screenshots
See the `screenshots/` folder: healthy stack, products page, app down, app recovered, restore, Docker Hub.
