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

# P: ShopLite project, full guide

ShopLite is a small shop made of three containers.

- **nginx** is the only public service. It serves the web page and forwards `/api/` requests to the app.
- **app** is a Flask API (run by gunicorn) that reads products from the database.
- **db** is PostgreSQL. It stores the products in a named volume.

Two networks keep the layers apart. `frontend` holds nginx and app. `backend` holds app and db. The app sits on both, so it can talk to both sides, but nginx can never reach the database directly. Only nginx publishes a port (host `8088` to container `80`).

```
browser --> nginx (8088) --> app (5000) --> db (5432)
            [frontend]       [frontend+backend]   [backend]
```

---

## 1. Folder layout

```bash
cd ~/devops-linux
mkdir -p docker/{nginx/site,app,db,scripts,screenshots}
```

`mkdir -p` creates the folders and does not complain if they already exist. The curly braces create all of them in one command.

```
docker/
  compose.yaml        wires the three services together
  .env.example        template for the secrets (committed)
  .env                the real values (never committed)
  nginx/              Dockerfile, nginx.conf, site/index.html
  app/                Dockerfile, app.py, requirements.txt
  db/init.sql         creates and fills the products table
  scripts/            backup.sh, health_check.sh
  screenshots/        proof for the README
```

---

## 2. The files and what each part does

### `.env.example` and `.env`

```
POSTGRES_USER=shop
POSTGRES_PASSWORD=change_me
POSTGRES_DB=shoplite
```

These are the database credentials. The `.env.example` file is a template with placeholder values, and it is committed to Git. The real `.env` is created from it and stays on your machine, because `.gitignore` lists `.env`. Passwords never go into an image or into Git.

```bash
cd ~/devops-linux/docker
cp .env.example .env        # copy the template, then put a real password in .env
```

### `db/init.sql`

```sql
CREATE TABLE IF NOT EXISTS products (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  price NUMERIC(10,2) NOT NULL
);
INSERT INTO products (name, price) VALUES
  ('Notebook', 4.50), ('Pen Set', 3.25), ('Backpack', 29.99),
  ('Water Bottle', 8.75), ('Desk Lamp', 15.00);
```

- `CREATE TABLE IF NOT EXISTS` makes the table only if it is missing.
- `SERIAL PRIMARY KEY` gives every row an automatic unique id.
- `NUMERIC(10,2)` stores money exactly, with 2 decimal places.
- The `INSERT` loads 5 starter products.

Postgres runs this file **only on the first start, when the data volume is empty**. That is why it is safe to restart the stack without duplicating products.

### `app/app.py`

```python
import os
import psycopg2
from flask import Flask, jsonify

app = Flask(__name__)

def get_conn():
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        dbname=os.environ["POSTGRES_DB"],
        user=os.environ["POSTGRES_USER"],
        password=os.environ["POSTGRES_PASSWORD"],
    )

@app.route("/api/health")
def health():
    return "OK", 200

@app.route("/api/products")
def products():
    conn = get_conn()
    try:
        cur = conn.cursor()
        cur.execute("SELECT id, name, price FROM products ORDER BY id")
        rows = [{"id": r[0], "name": r[1], "price": float(r[2])} for r in cur.fetchall()]
        return jsonify(rows)
    finally:
        conn.close()
```

- `get_conn()` reads every connection detail from environment variables, so no password is written in the code. `DB_HOST` is `db`, the service name, which Docker's DNS turns into the database container's IP.
- `/api/health` returns `OK` and does not touch the database. The Compose healthcheck uses it to see if the app process is alive.
- `/api/products` runs the query and returns the rows as JSON. The `finally` block always closes the connection, even if the query fails.

### `app/requirements.txt`

```
flask==3.0.3
psycopg2-binary==2.9.9
gunicorn==22.0.0
```

Versions are pinned, so every build installs the same packages. `psycopg2-binary` is the Postgres driver, and `gunicorn` is a production web server (Flask's built-in server is only for development).

### `app/Dockerfile`

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
RUN useradd --system --no-create-home appuser
USER appuser
EXPOSE 5000
CMD ["gunicorn", "-b", "0.0.0.0:5000", "app:app"]
```

| Line | Why |
|---|---|
| `FROM python:3.12-slim` | small Debian-based Python image |
| `WORKDIR /app` | all later commands run in `/app` |
| `COPY requirements.txt .` then `RUN pip install` | dependencies first, so this layer is cached and only rebuilt when `requirements.txt` changes |
| `--no-cache-dir` | no pip download cache stored in the image, so it is smaller |
| `COPY app.py .` | code last, because it changes most often |
| `useradd` and `USER appuser` | the app runs as a normal user, not root |
| `EXPOSE 5000` | documents the port (does not publish it) |
| `CMD [...]` | starts gunicorn on all interfaces, serving the `app` object from `app.py` |

### `nginx/nginx.conf`

```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location /api/ {
        resolver 127.0.0.11 valid=10s;
        set $upstream http://app:5000;
        proxy_pass $upstream;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

- `location /` serves the static page from the html folder.
- `location /api/` forwards API calls to the app container.
- `resolver 127.0.0.11` is Docker's built-in DNS. Putting the address in a variable (`$upstream`) makes nginx look up `app` at request time instead of once at startup. So nginx starts fine even if the app is down, and it finds the app again after the app restarts. When the app is down, the result is a `502 Bad Gateway` for `/api/` only, and the page itself still loads.
- The two `proxy_set_header` lines pass the original host and client IP to the app.

### `nginx/Dockerfile`

```dockerfile
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY site/ /usr/share/nginx/html/
EXPOSE 80
```

It starts from the small Alpine nginx image, replaces the default site config with ours, and copies the web page into nginx's html folder.

### `nginx/site/index.html`

The page shows the shop header and a Products section. A small script calls `fetch('/api/products')` and lists the result. If the call fails, it shows "Products unavailable", which is what you see when the app is stopped.

### `compose.yaml`

```yaml
services:
  db:
    image: postgres:16-alpine
    env_file: .env
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    networks: [backend]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 5s
      timeout: 3s
      retries: 10
    restart: unless-stopped

  app:
    build: ./app
    image: laxmi707/shoplite-app:v1.0
    env_file: .env
    environment:
      DB_HOST: db
    networks: [frontend, backend]
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5000/api/health')"]
      interval: 10s
      timeout: 3s
      retries: 5
    restart: unless-stopped

  nginx:
    build: ./nginx
    image: laxmi707/shoplite-nginx:v1.0
    ports:
      - "8088:80"
    networks: [frontend]
    depends_on:
      app:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "-q", "-O", "/dev/null", "http://127.0.0.1/"]
      interval: 10s
      timeout: 3s
      retries: 5
    restart: unless-stopped

networks:
  frontend:
  backend:

volumes:
  pgdata:
```

| Setting | What it does |
|---|---|
| `image:` (db) | official Postgres 16 on Alpine |
| `env_file: .env` | loads the credentials from `.env` into the container |
| `pgdata:/var/lib/postgresql/data` | named volume, so the data survives container removal |
| `./db/init.sql:...:ro` | mounts the SQL file where Postgres looks for start-up scripts, read-only |
| `networks:` | puts each service on only the networks it needs |
| `healthcheck:` | Docker runs the `test` command repeatedly and marks the container healthy or unhealthy |
| `$${POSTGRES_USER}` | the double `$` stops Compose from substituting the value on the host, so the container's own shell fills it in |
| `build:` plus `image:` | builds from the folder and names the result, ready to push to Docker Hub |
| `depends_on: condition: service_healthy` | starts a service only after the one it needs is healthy: db, then app, then nginx |
| `ports: "8088:80"` | host port 8088 maps to nginx's port 80. This is the only published port |
| `restart: unless-stopped` | brings a container back after a crash or reboot, unless you stopped it on purpose |
| `volumes: pgdata:` | declares the named volume |

---

## 3. Scripts

Make them executable once:

```bash
cd ~/devops-linux/docker
chmod +x scripts/*.sh
```

### `scripts/backup.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; source .env; set +a

BACKUP_DIR=./backups
mkdir -p "$BACKUP_DIR"
FILE="$BACKUP_DIR/shoplite_$(date +%Y%m%d_%H%M%S).sql"

docker compose exec -T db pg_dump -U "$POSTGRES_USER" --clean --if-exists "$POSTGRES_DB" > "$FILE"

# keep only the newest 7
ls -1t "$BACKUP_DIR"/shoplite_*.sql | tail -n +8 | xargs -r rm --
echo "$(date '+%F %T') backup saved: $FILE"
```

| Line | Meaning |
|---|---|
| `#!/usr/bin/env bash` | run the script with bash |
| `set -euo pipefail` | stop on any error (`-e`), on an unset variable (`-u`), and when any command in a pipe fails (`pipefail`), so a half-failed backup isn't treated as a success |
| `cd "$(dirname "$0")/.."` | move to the `docker/` folder, whatever folder you run it from, so `compose.yaml` and `.env` are found |
| `set -a; source .env; set +a` | load the variables from `.env` into the script (`-a` exports them) |
| `mkdir -p "$BACKUP_DIR"` | create `backups/` if missing |
| `FILE=...$(date ...)` | builds a timestamped name, such as `shoplite_20261119_055312.sql` |
| `docker compose exec -T db pg_dump ...` | runs `pg_dump` inside the db container. `-T` turns off the pseudo-terminal so the output can be redirected to a file |
| `--clean --if-exists` | the dump starts with `DROP TABLE IF EXISTS`, so restoring replaces the table cleanly |
| `> "$FILE"` | saves the dump on the host |
| `ls -1t ... \| tail -n +8 \| xargs -r rm --` | list newest first, skip the first 7, delete the rest. `-r` means do nothing if the list is empty |
| `echo ...` | prints when and where the backup was saved |

### `scripts/health_check.sh`

```bash
#!/usr/bin/env bash
cd "$(dirname "$0")/.."
LOG=./health_check.log

for svc in db app nginx; do
  cid=$(docker compose ps -q "$svc")
  if [ -z "$cid" ]; then
    echo "$(date '+%F %T') $svc missing, starting" | tee -a "$LOG"
    docker compose up -d "$svc"
    continue
  fi
  status=$(docker inspect -f '{{.State.Health.Status}}' "$cid")
  if [ "$status" != "healthy" ]; then
    echo "$(date '+%F %T') $svc is $status, restarting" | tee -a "$LOG"
    docker compose restart "$svc"
  else
    echo "$(date '+%F %T') $svc healthy" | tee -a "$LOG"
  fi
done
```

| Line | Meaning |
|---|---|
| `cd "$(dirname "$0")/.."` | same trick as before: work from the `docker/` folder |
| `LOG=./health_check.log` | where results are recorded (ignored by Git) |
| `for svc in db app nginx` | check each service in turn |
| `docker compose ps -q "$svc"` | prints the container id, and nothing if it isn't running |
| `[ -z "$cid" ]` | no container id means the service is stopped or missing, so start it with `up -d` |
| `docker inspect -f '{{.State.Health.Status}}'` | reads the health status Docker already tracks: `healthy`, `unhealthy` or `starting` |
| `!= "healthy"` | restart anything that isn't healthy |
| `tee -a "$LOG"` | prints the message and appends it to the log file |

Run it by hand, or from cron every 5 minutes:

```bash
./scripts/health_check.sh
# optional, in crontab -e:
# */5 * * * * /home/<you>/devops-linux/docker/scripts/health_check.sh
```

---

## 4. Build and run

```bash
cd ~/devops-linux/docker
docker info | grep 'Operating System'    # confirm you are on the engine you expect
docker compose up -d --build
docker compose ps
```

| Command | What it does |
|---|---|
| `docker compose up -d --build` | builds the app and nginx images, creates the networks and volume, and starts all three services in the background (`-d`). Start order follows `depends_on`: db, then app, then nginx |
| `docker compose ps` | lists the services. Wait until all three say `(healthy)` (about 30 to 40 seconds) |

Check that everything works:

```bash
curl -s localhost:8088/api/health        # OK
curl -s localhost:8088/api/products      # JSON with 5 products
```

Then open `http://localhost:8088` in the browser. You should see the shop page and the 5 products listed. This also proves the whole chain: browser, nginx, app, db.

Other useful commands:

```bash
docker compose logs --tail 20 app        # last 20 log lines of one service
docker compose logs -f                   # follow all logs; Ctrl+C to stop
docker compose images                    # images used by the stack
```

---

## 5. Prove the network isolation

```bash
docker compose exec nginx ping -c 1 db
docker compose exec app python -c "import socket; print(socket.gethostbyname('db'))"
```

- From **nginx**, `ping db` fails with `bad address 'db'`. nginx is only on `frontend`, so it can't even resolve the database's name.
- From **app**, the name `db` resolves to an IP (for example `172.20.0.2`), because the app is on `backend`.

This is the design goal: the public-facing container cannot reach the database, and only the app can.

---

## 6. Failure tests

### Test 1: the app goes down

```bash
docker compose stop app
curl -s -o /dev/null -w "site: %{http_code}\n" localhost:8088/
curl -i localhost:8088/api/products
```

- The site returns `200`, because nginx serves the page itself.
- `/api/products` returns `502 Bad Gateway`, because nginx can't reach the app.
- In the browser, the page loads and shows "Products unavailable".

Recover:

```bash
docker compose start app
sleep 30
docker compose ps                        # app (healthy) again
curl -s localhost:8088/api/products      # 5 products again
```

### Test 2: down and up keeps the data

```bash
docker compose down
docker compose up -d
sleep 40
docker compose ps
curl -s localhost:8088/api/products
```

`down` removes the containers and networks but **keeps the `pgdata` volume**, so the same 5 products come back. Don't add `-v`: `down -v` deletes the volume and the data. Confirm the volume exists with `docker volume ls | grep pgdata`.

### Test 3: delete data, then restore from a backup

```bash
./scripts/backup.sh
LATEST=$(ls -t backups/*.sql | head -1)
echo "$LATEST"

docker compose exec db psql -U shop -d shoplite -c "DELETE FROM products WHERE id=1;"
docker compose exec db psql -U shop -d shoplite -c "SELECT count(*) FROM products;"      # 4

docker compose exec -T db psql -U shop -d shoplite < "$LATEST"
docker compose exec db psql -U shop -d shoplite -c "SELECT count(*) FROM products;"      # 5
curl -s localhost:8088/api/products                                                      # Notebook is back
```

- `LATEST=$(ls -t backups/*.sql | head -1)` picks the newest backup file.
- `psql -c "..."` runs one SQL statement inside the db container.
- The restore feeds the dump file into `psql` through standard input (`<`), so `-T` is needed again. Because the dump was made with `--clean --if-exists`, it drops the table and recreates it with the saved rows.

### Test 4: the health script repairs the stack

```bash
docker compose stop app
./scripts/health_check.sh                # prints "app missing, starting" and starts it
docker compose ps
cat health_check.log
```

---

## 7. Publish the images and tag the release

```bash
docker login -u laxmi707                 # use a Docker Hub access token as the password
docker push laxmi707/shoplite-nginx:v1.0
docker push laxmi707/shoplite-app:v1.0
docker manifest inspect laxmi707/shoplite-app:v1.0 > /dev/null && echo "app image on Hub"
```

- Create the token in Docker Hub: Account settings, Personal access tokens, with Read and Write rights. Never paste it into a file in the repo.
- Compose already tagged the images with these names (`image:` in `compose.yaml`), so no `docker tag` is needed.
- `docker manifest inspect` asks Docker Hub directly, which confirms the push worked.

Commit and release through a branch and a pull request, merging on GitHub **before** pulling:

```bash
git switch -c feature/docs
git add docker/README.md docker/screenshots
git commit -m "Add README and screenshots"
git push -u origin feature/docs
# merge the pull request in the browser, wait for the Merged badge, then:
git switch main && git pull
git tag -a docker-v1.0 -m "ShopLite Docker stack v1.0"
git push origin docker-v1.0
```

---

## 8. Stop and clean up

```bash
docker compose down            # stops and removes containers and networks, keeps the data
docker compose down -v         # also deletes the pgdata volume (data is lost)
docker compose restart app     # restart a single service
```

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
