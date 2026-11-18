# Docker Notes

DevOps Trainee, Git & Docker task. Laxmi Kumbar. Repo: devops-linux

This file logs every Docker command I ran, with an explanation of what it does, when to use it, and which command is better when two look alike. Each block ends with a place for my own terminal output.

| Block | Topic |
|---|---|
| 1 | Why containers |
| 2 | Running containers |
| 3 | Images and Dockerfile |
| 4 | Data and networking |
| 5 | Docker Compose |
| 6 | Good practice |
| P | ShopLite project commands |
| Q | Quiz answers (1 to 10) |

---

# Block 1: Why containers

## Theory

### Containers vs virtual machines

A **virtual machine** is a whole computer in software. A hypervisor gives each VM virtual hardware, and each VM boots its own full operating system with its own kernel. A **container** is an ordinary process on the host that Docker isolates. It **shares the host kernel** and carries only the files and libraries the app needs.

| | Container | Virtual machine |
|---|---|---|
| Kernel | Shares the host kernel | Own kernel per VM |
| Size | Megabytes | Gigabytes |
| Startup | Under a second | Tens of seconds to minutes |
| Isolation | Process level (weaker) | Hardware level (stronger) |
| Overhead | Very low | High (a whole OS each) |
| Best for | Packaging and running apps | Running different OSes, strong isolation |

A Linux container can't run a different kernel (for example Windows), but it starts in milliseconds and uses far less memory.

### Image vs container vs registry

- **Image:** a read-only template (app, libraries, filesystem) built from layers.
- **Container:** a running or stopped instance of an image, with a thin writable layer on top. Many containers can start from one image.
- **Registry:** a server that stores images. **Docker Hub** is the default. A full name looks like `registry/user/name:tag`, and `nginx` is short for `docker.io/library/nginx:latest`.
- `latest` is only the default tag, not a guarantee of "newest". Real projects pin a version such as `postgres:16-alpine`.

### How Docker works (architecture)

The `docker` command is a **client**. It talks to the **Docker daemon** (`dockerd`), which manages images, containers, networks and volumes. The daemon uses **containerd** and **runc** to actually create the isolated process.

### Namespaces and cgroups

Linux has two features that together make a container:

- **Namespaces** control what a process can **see**. That is the isolation.
- **Cgroups** control what a process can **use** (memory, CPU). That is the limit.

| Namespace | Isolates | Effect inside a container |
|---|---|---|
| PID | Process IDs | The app is PID 1 and can't see host processes |
| NET | Network | Its own IP address and ports |
| MNT | Filesystem mounts | Its own root filesystem |
| UTS | Hostname | Its own hostname |
| IPC | Shared memory | Can't touch the host's IPC |
| USER | User IDs | Separate user mapping (optional) |

A container is not a small machine. It is a normal host process seen through these isolated views.

## Commands

| Command | What it does | When and why |
|---|---|---|
| `docker --version` | Shows the Docker version | Check the install |
| `docker run hello-world` | Pulls the image if needed, creates a container, runs it | First test of the whole pipeline |
| `docker images` | Lists local images | See what is stored and how big |
| `docker ps` | Lists running containers | See what is up |
| `docker ps -a` | Lists all containers, including stopped | Find exited containers |
| `docker run -d --name web-d1 nginx` | Runs nginx in the background with a name | Long-running servers |
| `docker logs web-d1` | Prints a container's output | Debugging |
| `docker stop web-d1` | Stops a running container gracefully | Normal shutdown |
| `docker rm web-d1` | Deletes a stopped container | Cleanup (the image stays) |
| `docker run -it --rm ubuntu bash` | Interactive shell in a throwaway Ubuntu container | Explore or test inside a clean OS |
| `docker run -d --memory 100m nginx` | Runs with a memory limit (a cgroup) | Show resource limits |
| `docker stats --no-stream <name>` | One-time snapshot of CPU and memory | See usage and limits |
| `docker top <name>` | Shows the container's processes as the host sees them | See the namespace view |
| `docker pull nginx:alpine` | Downloads an image without running it | Pre-fetch or update an image |
| `docker search nginx` | Searches Docker Hub | Find an image |

## What happened at each step

**`docker run hello-world`**
1. The client asked the daemon to run `hello-world`.
2. The daemon didn't find the image locally.
3. It pulled the image from Docker Hub.
4. It created a container and ran it. The program printed its message and exited, so the container stopped (`Exited (0)`).
5. Running it again doesn't pull again, because the image is cached.

**`docker run -d --name web-d1 nginx`**
1. Pulled the nginx image (several layers) and created a container.
2. nginx is a server that never exits by itself, so the container keeps running.
3. `docker stop` made it exit, `docker rm` deleted the container, and the image remained.

**`docker run -it --rm ubuntu bash`**
1. Pulled `ubuntu`, which is a base filesystem and not a full OS (it has no kernel).
2. `-i` keeps input open and `-t` gives a terminal, so together they give a shell.
3. `ps aux` showed only a few processes because of the PID namespace.
4. `exit` ended the main process, so the container stopped and `--rm` deleted it.

## Which is better

- `docker run -d` vs plain `docker run`: use `-d` for servers, because without it the terminal is blocked until `Ctrl+C`.
- `--rm`: use it for throwaway containers so they don't pile up in `docker ps -a`.

## My practice log

<!-- paste real output: docker run hello-world, docker ps -a, docker images, docker stats --no-stream -->

---

# Block 2: Running containers

## Theory

`docker run` is really three steps in one: **create** the container from an image, **start** it, and optionally **attach** your terminal. A container lives as long as its main process lives. When that process exits, the container stops, but it still exists (and keeps its writable layer) until you `docker rm` it.

Data written inside a container lives in its writable layer and is lost when the container is removed. D4 fixes that with volumes.

## `docker run` flags

| Flag | Meaning | Example |
|---|---|---|
| `-d` | Detached: run in the background | `docker run -d nginx` |
| `-p host:container` | Publish a container port on the host | `-p 8080:80` |
| `--name` | Give the container a name | `--name web` |
| `-e KEY=value` | Set an environment variable | `-e MY_NAME=Laxmi` |
| `--rm` | Delete the container when it exits | `docker run --rm alpine echo hi` |
| `-it` | Interactive terminal | `docker run -it ubuntu bash` |
| `-v` | Mount a volume or folder | `-v pgdata:/var/lib/postgresql/data` |
| `--network` | Attach to a network | `--network appnet` |
| `--memory`, `--cpus` | Resource limits (cgroups) | `--memory 100m --cpus 0.5` |
| `--restart` | Restart policy | `--restart unless-stopped` |

`-p 8080:80` means "host port 8080 goes to container port 80". To bind to localhost only, use `-p 127.0.0.1:8080:80`.

## Commands

| Command | What it does | When and why |
|---|---|---|
| `docker run -d -p 8080:80 --name web nginx` | Runs nginx and publishes it on port 8080 | Serve a page at `localhost:8080` |
| `docker ps`, `docker ps -a` | Running containers, or all containers | Check state |
| `docker logs web` | Prints logs once | Check output |
| `docker logs -f web` | Follows logs live | Watch requests while refreshing the page. `Ctrl+C` stops watching, not the container |
| `docker exec -it web sh` | Opens a shell inside a running container | Look around or edit files |
| `docker exec web printenv MY_NAME` | Runs one command and returns | Quick checks |
| `docker stop web` | Sends SIGTERM, then SIGKILL after 10 seconds | Graceful stop |
| `docker kill web` | Sends SIGKILL at once | A hung container |
| `docker start web` | Starts a stopped container (keeps its data) | Resume |
| `docker restart web` | Stop then start | Apply a change |
| `docker rm web` | Deletes a stopped container | Cleanup |
| `docker rm -f web` | Kills and deletes in one go | Throwaway containers |
| `docker inspect web` | Full JSON about the container | Find IP, mounts, env |
| `docker inspect -f '{{.NetworkSettings.IPAddress}}' web` | Pulls one field using a template | Quick lookups |
| `docker inspect -f '{{json .Mounts}}' web` | Shows mounts (`[]` means none) | Check volumes |
| `docker stats web` | Live CPU and memory | Monitor |
| `docker stats --no-stream web` | One snapshot | Put in notes |
| `docker top web` | Processes in the container | See what is running |
| `docker cp web:/etc/nginx/nginx.conf .` | Copies a file out of (or into) a container | Grab a config |
| `docker container prune` | Removes all stopped containers | Cleanup |

## Hands-on task: edit the page live

```bash
docker run -d -p 8080:80 --name web nginx
docker exec -it web sh
cd /usr/share/nginx/html
echo "<h1>Edited live by Laxmi</h1>" > index.html
exit
```
Refresh `http://localhost:8080` and the new heading appears with no restart. After `docker rm -f web` and a fresh `docker run`, the edit is gone, because it lived only in that container's writable layer.

## Which is better

- **`docker stop` vs `docker kill` vs `docker rm -f`:** `stop` lets the app shut down cleanly (best for databases). `kill` and `rm -f` are immediate. Use them for hung or throwaway containers.
- **`docker exec` vs `docker attach`:** `exec -it web sh` starts a new shell, and exiting it leaves the container running. `attach` connects to the main process, and exiting can stop it. Prefer `exec`.
- **`docker logs` vs `docker logs -f`:** the second follows live. Use it while testing.
- **`docker run` vs `docker start`:** `run` always creates a **new** container. `start` restarts an existing one.

## My practice log

<!-- paste real output: docker ps showing 0.0.0.0:8080->80/tcp, docker inspect IP, docker inspect Mounts, docker stats --no-stream web -->

---

# Block 3: Images and Dockerfile

## Theory

### Layers and cache

An image is a stack of read-only **layers**. Each `RUN`, `COPY` and `ADD` instruction creates a layer. Layers are cached. If an instruction and everything above it are unchanged, Docker reuses the cached layer and prints `CACHED`. When one instruction changes, that layer and **every layer after it** are rebuilt.

So the order of instructions affects build speed. Put things that change rarely (installing dependencies) **before** things that change often (your source code). For a Python app, copy `requirements.txt` and run `pip install` first, then copy the code. Changing code then doesn't reinstall packages.

### Dockerfile instructions

| Instruction | What it does |
|---|---|
| `FROM` | Sets the base image. Every Dockerfile starts here |
| `RUN` | Runs a command **at build time** and saves the result as a layer |
| `COPY src dest` | Copies files from the build context into the image |
| `ADD` | Like `COPY`, but can also extract archives and fetch URLs. Prefer `COPY` |
| `WORKDIR` | Sets the working folder for the instructions after it |
| `ENV` | Sets an environment variable, available at build and at run time |
| `ARG` | A build-time-only variable |
| `EXPOSE` | Documents the port the app listens on. It does **not** publish it |
| `USER` | Sets the user the container runs as |
| `CMD` | The default command or arguments. Replaced by `docker run` arguments |
| `ENTRYPOINT` | The fixed program. Run arguments are added after it |
| `HEALTHCHECK` | Defines how to test that the app is healthy |

### CMD vs ENTRYPOINT

- `CMD` is a **default** that anything after the image name in `docker run` replaces.
- `ENTRYPOINT` is the **fixed program**. Arguments from `docker run` are passed to it.
- Together: `ENTRYPOINT ["echo","Hello"]` and `CMD ["World"]` print "Hello World"; `docker run img Laxmi` prints "Hello Laxmi".
- `--entrypoint` on the command line overrides the ENTRYPOINT.
- Prefer the **exec form** `["cmd","arg"]` over the shell form `cmd arg`, so the app receives signals correctly and `docker stop` works cleanly.

### The build context and `.dockerignore`

`docker build .` sends the folder `.` (the **build context**) to the daemon. A `.dockerignore` file lists what to leave out, like `.git`, `*.log` and `.env`. This makes builds faster and keeps secrets out of the image.

## Commands

| Command | What it does | When and why |
|---|---|---|
| `docker build -t shoplite:v1 .` | Builds an image from the Dockerfile in `.` and tags it | Build your own image |
| `docker build --no-cache -t x .` | Builds ignoring the cache | Force a clean rebuild |
| `docker images` | Lists images and sizes | Compare sizes |
| `docker history shoplite:v1` | Shows each layer and its size | See what makes the image big |
| `docker tag shoplite:v1 user/shoplite:v1` | Adds another name to an image | Prepare a push |
| `docker rmi shoplite:v1` | Removes an image | Cleanup. Fails if a container uses it |
| `docker image prune` | Removes dangling (untagged) images | Cleanup |
| `docker image inspect shoplite:v1` | Details about the image | Check size, layers, config |

## Hands-on task: ShopLite with Nginx

```bash
cd ~/devops-linux/docker/nginx
cp -r ~/devops-linux/project/site ./site
cat > Dockerfile <<'EOF'
FROM nginx
COPY site/ /usr/share/nginx/html/
EXPOSE 80
EOF
docker build -t shoplite:v1 .
docker run -d --name shop -p 8081:80 shoplite:v1
docker history shoplite:v1
```
The `COPY` layer is tiny compared with the nginx base layers. Editing `site/index.html` and rebuilding reruns only the `COPY` layer, and everything above it shows `CACHED`.

## Which is better

- **`COPY` vs `ADD`:** use `COPY`. It does exactly one thing and is predictable.
- **`CMD` vs `ENTRYPOINT`:** use `CMD` for a default that users may replace. Use `ENTRYPOINT` when the container is built around one program.
- **`ENV` vs `ARG`:** `ARG` is build-time only. `ENV` stays in the final image, so never put a secret in either.
- **`EXPOSE` vs `-p`:** `EXPOSE` is documentation. Only `-p` actually opens the port on the host.

## My practice log

<!-- paste real output: docker history shoplite:v1, docker build (CACHED lines), CMD vs ENTRYPOINT demo -->

---

# Block 4: Data and networking

## Theory: data

A container's writable layer is deleted with the container. To keep data you mount storage into it.

| | Volume | Bind mount | tmpfs |
|---|---|---|---|
| What | Storage managed by Docker (`/var/lib/docker/volumes/...`) | A host folder mapped into the container | Memory only |
| Syntax | `-v pgdata:/var/lib/postgresql/data` | `-v "$(pwd)":/usr/share/nginx/html:ro` | `--tmpfs /tmp` |
| Best for | Databases, anything to persist | Live editing code or config | Temporary secrets or scratch data |
| Survives `docker rm` | Yes | Yes (it's your folder) | No |

Add `:ro` to a mount to make it read-only inside the container.

## Theory: networking

Docker creates **bridge** networks. Containers on the same network can reach each other, and on a **user-defined** network they find each other **by container name** through Docker's built-in DNS. The **default** `bridge` network has **no** name resolution.

| Network driver | Use |
|---|---|
| `bridge` | Default. Containers on one host, isolated from the outside unless ports are published |
| `host` | Container shares the host's network (no isolation, Linux only) |
| `none` | No network at all |

A container only needs `-p` to be reached from **outside** Docker. Container-to-container traffic on a shared network needs no published port.

## Commands

| Command | What it does | When and why |
|---|---|---|
| `docker volume create pgdata` | Creates a named volume | Prepare storage |
| `docker volume ls` | Lists volumes | See what exists |
| `docker volume inspect pgdata` | Shows details and the host path | Find where data lives |
| `docker volume rm pgdata` | Deletes a volume (and its data) | Only when sure |
| `docker volume prune` | Removes unused volumes | Cleanup (check first) |
| `docker network create appnet` | Creates a user-defined bridge network | Name-based networking |
| `docker network ls` | Lists networks | See what exists |
| `docker network inspect appnet` | Shows connected containers and IPs | Check who is attached |
| `docker network connect appnet n2` | Attaches a running container to a network | Join a network later |
| `docker network disconnect appnet n2` | Detaches it | Isolate |
| `docker network rm appnet` | Deletes a network | Cleanup |

## Hands-on tasks

**Postgres with a named volume (data survives)**
```bash
docker volume create pgdata
docker run -d --name pg1 -e POSTGRES_PASSWORD=secret \
  -v pgdata:/var/lib/postgresql/data postgres:16-alpine
until docker exec pg1 pg_isready -U postgres; do sleep 1; done
docker exec pg1 psql -U postgres -c "CREATE TABLE notes(id int, txt text);"
docker exec pg1 psql -U postgres -c "INSERT INTO notes VALUES (1,'hello'),(2,'world');"
docker rm -f pg1
docker run -d --name pg2 -e POSTGRES_PASSWORD=secret \
  -v pgdata:/var/lib/postgresql/data postgres:16-alpine
docker exec pg2 psql -U postgres -c "SELECT * FROM notes;"    # same rows
```
The container was disposable, but the data stayed in the volume.

**Two containers by name**
```bash
docker network create appnet
docker run -d --name n1 --network appnet nginx:alpine
docker run -it --rm --network appnet alpine ping -c 3 n1       # works
docker run -d --name n2 nginx:alpine                           # default bridge
docker run --rm alpine ping -c 2 n2                            # fails: bad address
docker network connect appnet n2
docker run --rm --network appnet alpine ping -c 2 n2           # now works
```

## Which is better

- **Volume vs bind mount:** volume for databases, because Docker manages it and it is portable. Bind mount for development, because host edits show up at once.
- **Default bridge vs user-defined bridge:** always use a user-defined network. It gives DNS by name and better isolation.
- **`docker volume rm` vs `prune`:** `rm` targets one volume. `prune` removes every unused volume, so check `docker volume ls` first.

## My practice log

<!-- paste real output: SELECT from pg2, docker volume ls, docker volume inspect pgdata, both ping results -->

---

# Block 5: Docker Compose

## Theory

Compose describes a whole multi-container application in one file, `compose.yaml`, and starts everything with one command. Compose creates a **default network** for the project, so every service can reach every other by its **service name** (for example `db`).

### Key fields

| Field | Meaning |
|---|---|
| `services` | The containers to run |
| `image` / `build` | Use a prebuilt image, or build one from a folder |
| `ports` | Publish ports, `"8080:80"` |
| `volumes` | Mount named volumes or folders |
| `networks` | Which networks a service joins |
| `environment` | Variables written directly in the file |
| `env_file` | Variables loaded from a file such as `.env` |
| `depends_on` | Start order. With `condition: service_healthy` it waits for a passing healthcheck |
| `healthcheck` | A command that tests whether the service is truly ready |
| `restart` | `no`, `on-failure`, `always`, `unless-stopped` |

`depends_on` alone only waits for the container to **start**, not for the app inside to be **ready**. Use `condition: service_healthy` with a healthcheck for real readiness.

In a Compose file, `$$` means a literal `$`. Use `$$VAR` when you want the container's own shell to expand a variable instead of Compose.

## Example: Nginx and PostgreSQL

```yaml
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD: secret
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 3s
      retries: 10
    restart: unless-stopped

  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

volumes:
  pgdata:
```

## Commands

| Command | What it does | When and why |
|---|---|---|
| `docker compose up -d` | Creates and starts everything in the background | Start the stack |
| `docker compose up -d --build` | Rebuilds images first | After changing a Dockerfile |
| `docker compose ps` | Shows service status and health | Check it is healthy |
| `docker compose logs` | Shows logs of all services | Debug |
| `docker compose logs -f web` | Follows one service's logs | Watch live |
| `docker compose exec db psql -U postgres` | Runs a command in a running service | Use the database |
| `docker compose stop` / `start` | Stops or starts without removing | Pause |
| `docker compose restart web` | Restarts one service | Apply a change |
| `docker compose down` | Removes containers and networks, **keeps volumes** | Normal shutdown |
| `docker compose down -v` | Also removes volumes (**deletes data**) | Full reset |
| `docker compose config` | Prints the final merged config | Check for mistakes |
| `docker compose build` | Builds images only | Prepare for a push |

## Which is better

- **`down` vs `down -v`:** `down` keeps your data. `down -v` deletes the volumes. Never use `-v` before a persistence test.
- **`depends_on` vs `depends_on` with `service_healthy`:** the first only orders the start. The second really waits until the database is ready.
- **`environment` vs `env_file`:** use `env_file: .env` for values you don't want in the compose file, and keep `.env` out of Git.
- **`docker compose` vs `docker-compose`:** `docker compose` (with a space) is the current plugin. `docker-compose` is the old standalone tool.

## My practice log

<!-- paste real output: docker compose ps showing healthy, SELECT before and after down -v -->

---

# Block 6: Good practice

## Theory

| Rule | Why | Example |
|---|---|---|
| Small base image | Faster pulls and a smaller attack surface | `nginx:alpine`, `python:3.12-slim` |
| Pin versions | Repeatable builds | `postgres:16-alpine`, not `latest` |
| Non-root `USER` | A compromised app can't act as root | `RUN useradd --system appuser` then `USER appuser` |
| No secrets in images | Anyone with the image can read them (`docker history`, `docker inspect`) | Pass them at runtime from `.env` |
| `.dockerignore` | Keeps `.git`, `.env` and junk out of the build | `.env`, `.git`, `*.log` |
| Multi-stage builds | Ship only the final result, not the build tools | Build in one stage, copy into a slim one |
| One process per container | Simpler to scale and debug | Separate nginx, app and db |

### Multi-stage build

Each `FROM` starts a new stage. You build in a large stage with compilers and tools, then `COPY --from=build` only the result into a small final stage. The final image contains none of the build tooling.

```dockerfile
FROM python:3.12-slim AS build
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim
WORKDIR /app
COPY --from=build /install /usr/local
COPY app.py .
RUN useradd --system --no-create-home appuser
USER appuser
CMD ["gunicorn", "-b", "0.0.0.0:5000", "app:app"]
```

### Alpine vs slim

- **Alpine** is the smallest, but it uses musl instead of glibc, which can break some Python and compiled packages.
- **slim** (Debian-based) is a bit larger and more compatible. Use `-slim` for Python and `-alpine` for nginx and postgres.

## Commands

| Command | What it does | When and why |
|---|---|---|
| `docker images shoplite` | Compare image sizes (v1 vs v2) | Prove the slim base helped |
| `docker history <image> --no-trunc` | Full layer commands | Spot secrets and big layers |
| `docker system df` | Disk used by images, containers, volumes, cache | See what is taking space |
| `docker system prune` | Removes stopped containers, unused networks, dangling images and build cache | Cleanup. **Read the warning first** |
| `docker system prune -a` | Also removes all unused images | Aggressive cleanup |
| `docker system prune --volumes` | Also removes unused volumes (**deletes data**) | Only when sure |
| `docker login` | Signs in to Docker Hub | Before pushing |
| `docker tag shoplite:v2 user/shoplite:v1` | Names the image for your account | Before pushing |
| `docker push user/shoplite:v1` | Uploads to Docker Hub | Share or deploy |
| `docker pull user/shoplite:v1` | Downloads it again | Test that the push worked |

## Hands-on task: slim image and push

```bash
cd ~/devops-linux/docker/nginx
sed -i 's/^FROM nginx$/FROM nginx:alpine/' Dockerfile
docker build -t shoplite:v2 .
docker images shoplite                 # v2 is much smaller than v1

docker login
docker tag shoplite:v2 YOUR_DOCKERHUB_USER/shoplite:v1
docker push YOUR_DOCKERHUB_USER/shoplite:v1
```
Use a Docker Hub personal access token (**Settings, Personal access tokens**) when `docker login` asks for a password.

Why a secret in an image is dangerous:
```bash
printf 'FROM alpine\nENV DB_PASSWORD=supersecret\n' > Dockerfile
docker build -t secret-demo .
docker history secret-demo --no-trunc | grep DB_PASSWORD     # readable by anyone
```

## Which is better

- **`prune` vs `prune -a` vs `prune --volumes`:** use plain `prune` for routine cleanup. Add `-a` only to reclaim image space, and use `--volumes` only when you accept deleting data.
- **`latest` vs a pinned tag:** always pin. `latest` can change under you and break builds.
- **Baking a secret in vs runtime variables:** runtime variables (`.env`, `env_file`) are the right choice. Build-time secrets can use BuildKit `--mount=type=secret`.

## My practice log

<!-- paste real output: docker images shoplite (both sizes), docker system df, Docker Hub repo link -->

---

# P: ShopLite project commands

Three containers: **nginx** (public, port 8080), **app** (Flask API), **db** (Postgres). Two networks: `frontend` (nginx and app) and `backend` (app and db), so nginx can't reach the database. Only nginx publishes a port. Data lives in the named volume `pgdata`.

## Setup and run

```bash
cd ~/devops-linux/docker
cp .env.example .env                     # real values stay in .env (ignored by Git)
docker compose up -d --build
docker compose ps                        # all services healthy
curl localhost:8080/api/health
curl localhost:8080/api/products
```

## Prove the network isolation

```bash
docker compose exec nginx ping -c 1 db   # fails: bad address (different network)
docker compose exec app ping -c 1 db     # works (app is on both networks)
```

## Failure tests

| Test | Commands | Expected |
|---|---|---|
| App down | `docker compose stop app`, then `curl -i localhost:8080/api/products`, then `docker compose start app` | Site still loads; API returns 502; recovers after restart |
| Persistence | `docker compose down`, `docker compose up -d`, `curl localhost:8080/api/products` | Products still listed (never use `-v`) |
| Backup and restore | `./scripts/backup.sh`, then delete a row, then restore | Row is back |

```bash
./scripts/backup.sh
docker compose exec db psql -U shop -d shoplite -c "DELETE FROM products WHERE id=1;"
docker compose exec db psql -U shop -d shoplite -c "SELECT count(*) FROM products;"   # 4
docker compose exec -T db psql -U shop -d shoplite < backups/shoplite_YYYYMMDD_HHMMSS.sql
docker compose exec db psql -U shop -d shoplite -c "SELECT count(*) FROM products;"   # 5
```
Replace `YYYYMMDD_HHMMSS` with the real timestamp of your backup file.

## Scripts

- `backup.sh`: runs `pg_dump` inside the db container through `docker compose exec -T`, saves a timestamped `.sql` file, and keeps only the newest 7.
- `health_check.sh`: checks each service's health with `docker inspect`, restarts any that aren't healthy, and logs the result.

## Release

```bash
docker login
docker compose build
docker push YOUR_DOCKERHUB_USER/shoplite-nginx:v1.0
docker push YOUR_DOCKERHUB_USER/shoplite-app:v1.0
git tag -a docker-v1.0 -m "ShopLite Compose stack v1.0"
git push origin docker-v1.0
```

## Common mistakes

- Committing `.env` instead of `.env.example`.
- Using `localhost` as the database host inside the app (use the service name `db`).
- Running `docker compose down -v` before the persistence test.
- Editing `init.sql` and expecting it to run again (it runs only when the data volume is empty).
- Publishing `5432:5432`, which breaks "only nginx is open".

---

# Command comparison sheet

| Goal | Use this | Not this, and why |
|---|---|---|
| Run a server in the background | `docker run -d` | plain `run` blocks the terminal |
| Open a shell in a running container | `docker exec -it web sh` | `attach` can stop the container on exit |
| Stop gracefully | `docker stop` | `kill` is abrupt |
| Throwaway container | `docker run --rm` | leaves stopped containers behind |
| Persist database data | named volume | writable layer is deleted with the container |
| Edit code live | bind mount | volume is harder to edit from the host |
| Containers find each other by name | user-defined network | default bridge has no DNS |
| Copy files into an image | `COPY` | `ADD` has extra hidden behaviour |
| Default command users may override | `CMD` | |
| Fixed program | `ENTRYPOINT` | |
| Keep data on shutdown | `docker compose down` | `down -v` deletes volumes |
| Real startup ordering | `depends_on` with `service_healthy` | plain `depends_on` only orders the start |
| Routine cleanup | `docker system prune` | `--volumes` can delete data |
| Version of an image | pinned tag | `latest` can change |

---

# Quiz answers

**1. `git merge` vs `git rebase`, and when not to rebase.** Merge joins two branches with a merge commit and keeps history as it happened. Rebase replays your commits on top of another branch for a straight line, but creates new commits with new hashes. Don't rebase commits that are already pushed or that others have based work on, because it rewrites shared history and leaves everyone with diverged copies.

**2. A password was committed and pushed.** Treat it as compromised: change or revoke it immediately, because it stays in history and may already be copied. Then remove it from the repo (delete it and commit, and if needed rewrite history with `git filter-repo` or BFG and force push). Add the file to `.gitignore`, keep the value in `.env`, and commit a `.env.example` with placeholders.

**3. `git reset --hard` vs `git revert`.** `reset --hard` moves the branch back and deletes the changes, rewriting history. `revert` adds a new commit that reverses an earlier one and keeps history, so it is the safe choice for commits that are already pushed.

**4. Why protect `main` and use pull requests.** `main` is the trusted, deployable branch. Protection forces every change through review and checks, blocks accidental or unreviewed pushes and force pushes, and leaves a clear record of who changed what and why.

**5. Container vs virtual machine.** A VM runs a full guest operating system with its own kernel on virtual hardware. A container is an isolated process that shares the host kernel, isolated by namespaces and limited by cgroups. Containers are much smaller and start much faster, but their isolation is at process level, so it is less strict than a VM's.

**6. `CMD` vs `ENTRYPOINT`.** `CMD` sets the default command or arguments and is replaced by anything given after the image name in `docker run`. `ENTRYPOINT` sets the fixed program, and `docker run` arguments are passed to it. They are often combined: `ENTRYPOINT` is the program and `CMD` its default arguments. `--entrypoint` overrides the entrypoint.

**7. Why Dockerfile instruction order affects build speed.** Each instruction is a cached layer. When one instruction changes, its layer and all layers after it are rebuilt. So put rarely changing steps (installing dependencies) first and frequently changing steps (copying source code) last. For example, copy `requirements.txt` and run `pip install` before `COPY app.py`, so a code edit doesn't reinstall packages.

**8. Container data disappears when the container is removed. How do you keep it?** Mount a named volume (`-v pgdata:/var/lib/postgresql/data`) or a bind mount, so the data lives outside the container's writable layer. In Compose, declare it under `volumes:`. The data then survives `docker rm` and `docker compose down` (but not `down -v`).

**9. How do two containers in the same Compose file talk to each other?** Compose puts them on a shared network and gives each service a DNS name equal to its service name, so the app connects to the database at the host `db` and the port inside the network. No published port is needed. With custom networks, only services attached to the same network can reach each other.

**10. Why shouldn't a container run as root, and how do you change that?** If an attacker compromises a root process, they get root inside the container, which makes escaping to the host and damaging mounted data far easier. Running as a normal user limits the damage. In the Dockerfile, create a user and switch to it: `RUN useradd --system --no-create-home appuser` then `USER appuser`. Make sure the app can still read its files and uses a port above 1024.
