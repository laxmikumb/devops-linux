# ShopLite: Production Web Server Setup and Monitoring Automation

## 1. Overview

**Scenario:** ShopLite is a small e-commerce startup launching a static product website. They have one Ubuntu server and no ops team. My job as the DevOps engineer was to make the site **live, secure, backed up and monitored**, and to make the whole server **rebuildable with one command**.

**Core idea:** nothing is configured by hand twice. Every action is a script stored in this GitHub repo. If the server is destroyed, one command rebuilds it.

```
GitHub repo
   |
   v
bootstrap.sh  -> builds the server (user, SSH, firewall, fail2ban, Nginx)
   |
   v
deploy.sh     -> puts the website live safely (test first, rollback on failure)
   |
   v
cron          -> health_check.sh (every 5 min), backup.sh (01:00), log_report.sh (08:00)
```

## 2. Repository structure

| Path | Purpose |
|---|---|
| `scripts/bootstrap.sh` | Rebuilds the whole server on a fresh Ubuntu machine |
| `scripts/deploy.sh` | Pulls the latest site, tests Nginx config, reloads, rolls back on failure |
| `scripts/health_check.sh` | Checks CPU, memory, disk and Nginx; restarts Nginx if down; logs results |
| `scripts/backup.sh` | Timestamped backup of site and Nginx config, keeps the newest 7 |
| `scripts/log_report.sh` | Summary of the Nginx access log |
| `configs/nginx-shoplite.conf` | Nginx server block for the site |
| `configs/logrotate-shoplite` | Rotates `/var/log/shoplite/*.log` daily, keeps 7, compressed |
| `configs/crontab.txt` | Cron schedule |
| `site/index.html` | The ShopLite web page |
| `screenshots/` | Evidence for each deliverable |

## 3. Quick start (rebuild the server)

Run as root on a fresh Ubuntu machine (for example a Killercoda Ubuntu playground):

```bash
git clone https://github.com/laxmikumb/devops-linux.git /opt/shoplite
bash /opt/shoplite/project/scripts/bootstrap.sh 2>&1 | tee /root/bootstrap.log
```

| Part | Meaning |
|---|---|
| `git clone <url> /opt/shoplite` | Downloads the repo into `/opt/shoplite`, the folder the cron jobs expect |
| `bash script.sh` | Runs the script with bash |
| `2>&1` | Sends error messages into the normal output stream |
| `\| tee /root/bootstrap.log` | Shows the output on screen and also saves it to a log file |

Verify:

```bash
curl -I http://localhost
ufw status
fail2ban-client status sshd
crontab -l
sshd -T | grep -Ei "permitrootlogin|passwordauthentication"
```

---

## 4. Step-by-step: what I built and why

### Step 1: Workspace and repo

```bash
git clone https://github.com/laxmikumb/devops-linux.git
mkdir -p project/{scripts,configs,site,screenshots}
```

- `git clone` copies the GitHub repo to the machine.
- `mkdir -p` creates the folders; `-p` creates parents and does not fail if they exist; `{a,b,c}` creates all of them in one command.
- **Why:** the playground wipes after about 60 minutes, so GitHub is the permanent copy. The server is always rebuilt from it.

### Step 2: The website (`site/index.html`)

A simple HTML page with a header and three product cards. It is the product the client wants online.

### Step 3: Nginx web server and server block

Nginx is the program that listens for browser requests and sends back pages.

```bash
apt install -y nginx
```

`configs/nginx-shoplite.conf`:

```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name shoplite-web01 _;
    root /var/www/shoplite;
    index index.html;
    access_log /var/log/nginx/access.log;
    error_log  /var/log/nginx/error.log;
    location / {
        try_files $uri $uri/ =404;
    }
}
```

| Line | Meaning |
|---|---|
| `listen 80 default_server` | Answers web requests on port 80; used when no other site matches (needed on Killercoda, where the site is reached through a proxy link) |
| `server_name shoplite-web01 _` | The site name; `_` is a catch-all |
| `root /var/www/shoplite` | Folder the site files are served from |
| `index index.html` | The default page |
| `try_files $uri $uri/ =404` | Serve the file if it exists, otherwise return 404 |
| `access_log` / `error_log` | Where Nginx records requests and errors (`log_report.sh` reads the access log) |

Installing it by hand the first time:

```bash
mkdir -p /var/www/shoplite
cp project/site/index.html /var/www/shoplite/
cp project/configs/nginx-shoplite.conf /etc/nginx/sites-available/shoplite
ln -sf /etc/nginx/sites-available/shoplite /etc/nginx/sites-enabled/shoplite
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx
curl -I http://localhost
```

| Command | Meaning and why |
|---|---|
| `mkdir -p /var/www/shoplite` | Creates the folder Nginx serves from |
| `cp` | Puts the page and config where Nginx looks for them |
| `ln -sf <target> <link>` | Creates a **symlink** (shortcut). Nginx only loads configs linked into `sites-enabled`; `-f` replaces an existing link. Removing the link disables the site without deleting the real file |
| `rm -f .../default` | Removes the default "Welcome to nginx" site so ShopLite is served |
| `nginx -t` | **Tests the config** for mistakes before it is applied. A broken config could stop Nginx from starting |
| `systemctl reload nginx` | Applies the new config **without dropping connections** (`restart` would briefly drop them) |
| `curl -I http://localhost` | Fetches only the headers. `HTTP/1.1 200 OK` means the site works |

### Step 4: `health_check.sh` (monitoring and self-healing)

**What it does:** every run it measures CPU, memory and disk, writes one line to `/var/log/shoplite/health.log`, logs an `ALERT` if any value is above 80%, and checks whether Nginx is running. If Nginx is down, it restarts it and logs `FIXED`.

| Command in the script | Meaning and why |
|---|---|
| `vmstat 1 2 \| tail -1 \| awk '{print 100-$15}'` | CPU used % = 100 minus idle (column 15 of the second sample) |
| `free \| awk '/Mem:/ {printf "%.0f", $3/$2*100}'` | Memory used % = used / total * 100 |
| `df / \| awk 'NR==2 {gsub("%","",$5); print $5}'` | Disk used % of `/` as a plain number, so it can be compared with 80 |
| `${DISK_THRESHOLD:-80}` | Uses 80 unless overridden. Lets the demo trigger the alert on a big, empty disk |
| `log() { echo "$(date ...) $1" >> "$LOG_FILE"; }` | A function that writes a timestamped line to the log |
| `[ "$DISK" -gt "$DISK_THRESHOLD" ] && log "ALERT ..."` | If disk is above the threshold, log an alert |
| `systemctl is-active --quiet nginx` | Exit code 0 if Nginx is running; the `if` reads the exit code |
| `systemctl restart nginx` | The automatic fix |
| `exit 1` if the restart fails | Tells cron the job failed |

**Why:** if Nginx crashes at 3 AM, it is back within 5 minutes with no human involved.

**Test:**

```bash
systemctl stop nginx
/opt/shoplite/project/scripts/health_check.sh
tail -5 /var/log/shoplite/health.log
curl -I http://localhost
```

Result: `ALERT nginx is DOWN, restarting`, then `FIXED nginx restarted successfully`, and `200 OK`. (Screenshot: `health-autorestart.png`.)

### Step 5: `backup.sh` (protection against data loss)

```bash
tar -czf /var/backups/shoplite/shoplite_<timestamp>.tar.gz /var/www/shoplite /etc/nginx/sites-available/shoplite
ls -1t /var/backups/shoplite/shoplite_*.tar.gz | tail -n +8 | xargs -r rm -f --
```

| Command | Meaning and why |
|---|---|
| `date +%Y-%m-%d_%H%M%S` | Timestamp in the file name so every backup is unique |
| `tar -czf file.tar.gz paths` | `c` create, `z` gzip-compress, `f` file name. One compressed file holding the site and config |
| `if tar ...; then ... else ... rm -f "$FILE"` | Checks tar's exit code; on failure it deletes the broken partial archive so it cannot count as a good backup |
| `ls -1t` | Lists files one per line, newest first |
| `tail -n +8` | Starts at the 8th line, so the 7 newest are skipped (kept) |
| `xargs -r rm -f --` | Deletes the older ones; `-r` does nothing if the list is empty |

The archive is written to `/var/backups/shoplite`, **outside** the folder being archived. Creating an archive inside its own source folder makes tar try to include it.

**Why:** if someone deletes the site, it can be restored. Keeping only 7 limits disk use while keeping a week of history.

**Test and restore:**

```bash
/opt/shoplite/project/scripts/backup.sh
rm /var/www/shoplite/index.html
curl -I http://localhost          # 403 Forbidden (folder exists, page is gone)
tar -xzf $(ls -1t /var/backups/shoplite/*.tar.gz | head -1) -C / var/www/shoplite/index.html
curl -I http://localhost          # 200 OK
```

| Part | Meaning |
|---|---|
| `$(ls -1t ... \| head -1)` | The newest backup file |
| `tar -xzf` | `x` extract, `z` gzip, `f` file |
| `-C /` | Extract relative to the root, so the file returns to its original path |
| `var/www/shoplite/index.html` | Only this one file is extracted. It has no leading `/` because tar strips it |

Screenshots: `backup-delete-403.png` and `backup-restore-200.png`.

### Step 6: `log_report.sh` (understanding traffic)

```bash
wc -l < "$LOG"
awk '{print $1}' "$LOG" | sort | uniq -c | sort -nr | head -5
awk '{print $7}' "$LOG" | sort | uniq -c | sort -nr | head -5
awk '$9 ~ /^4/' "$LOG" | wc -l
awk '$9 ~ /^5/' "$LOG" | wc -l
```

| Command | Meaning and why |
|---|---|
| `LOG=${1:-/var/log/nginx/access.log}` | Uses the first argument if given, otherwise the default log, so it can be tested on a sample file |
| `[ ! -r "$LOG" ]` | Exits with an error if the log is missing or unreadable |
| `wc -l < "$LOG"` | Counts lines (one per request) without printing the file name |
| `awk '{print $1}'` | Field 1 of an Nginx log line is the client IP |
| `sort \| uniq -c \| sort -nr \| head -5` | `sort` groups identical values, `uniq -c` counts them, `sort -nr` ranks highest first, `head -5` keeps the top five |
| `awk '{print $7}'` | Field 7 is the requested page |
| `$9 ~ /^4/` | Field 9 is the status code; this matches codes starting with 4 (client errors). `^5` matches server errors |

**Why:** the owner learns who visits, which pages are popular, and whether errors are happening.

### Step 7: `deploy.sh` (safe updates with rollback)

Steps inside the script, in order:

1. `git pull --ff-only` downloads the newest site from GitHub (only if it is a clean fast-forward).
2. `cp -a` copies the current live site and config into a temporary folder (`mktemp -d`). This is the **snapshot** used for rollback.
3. It copies the new site and config into place, links the config into `sites-enabled`, and sets permissions:
   - `chown -R deploy:www-data /var/www/shoplite`: owner `deploy`, group `www-data` (the Nginx user)
   - `chmod 750` on folders and `chmod 640` on files: only `deploy` can edit, `www-data` can read, others get nothing
4. `nginx -t`: if it passes, `systemctl reload nginx`. If it fails, it restores the snapshot, tests again, reloads, and exits with an error.

`SKIP_PULL=1` skips the git pull, which is used by `bootstrap.sh` (the repo was just cloned) and for testing.

**Why:** a bad change can never take the live site down.

**Rollback test:**

```bash
echo "bad_directive on;" >> project/configs/nginx-shoplite.conf
SKIP_PULL=1 project/scripts/deploy.sh
curl -I http://localhost
git checkout project/configs/nginx-shoplite.conf
```

Result: `nginx -t FAILED, rolling back`, then `rollback complete`, and the site still returned `200 OK`. The last command restores the config file in the repo.

### Step 8: Scheduling with cron

`configs/crontab.txt`:

```
*/5 * * * * /opt/shoplite/project/scripts/health_check.sh
0 1 * * * /opt/shoplite/project/scripts/backup.sh >> /var/log/shoplite/backup.log 2>&1
0 8 * * * /opt/shoplite/project/scripts/log_report.sh >> /var/log/shoplite/report.log 2>&1
```

Cron format: `minute hour day-of-month month day-of-week command`.

| Expression | Meaning |
|---|---|
| `*/5 * * * *` | Every 5 minutes |
| `0 1 * * *` | Every day at 01:00 |
| `0 8 * * *` | Every day at 08:00 |

| Part | Why |
|---|---|
| Full paths | Cron runs with a minimal environment and a different working folder |
| `>> file` | Appends the script's output to a log |
| `2>&1` | Also captures errors in that log. Cron has no terminal, so without this output would be lost |

`health_check.sh` needs no redirect because it writes its own log lines.

Installed with `crontab configs/crontab.txt`; check with `crontab -l`.

### Step 9: Log rotation

`configs/logrotate-shoplite`:

```
/var/log/shoplite/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
```

| Option | Meaning |
|---|---|
| `daily` | Rotate once a day |
| `rotate 7` | Keep 7 old copies |
| `compress` | gzip the old copies |
| `missingok` / `notifempty` | No error if a log is missing; skip empty logs |

**Why:** the health log grows every 5 minutes. Rotation stops it from filling the disk. It is copied to `/etc/logrotate.d/shoplite` by `bootstrap.sh`.

### Step 10: `bootstrap.sh` (the most important script)

One script that builds the whole server on a blank machine.

| Section | Commands | Why |
|---|---|---|
| Root check | `[ "$(id -u)" -eq 0 ]` | Needs root to install and configure |
| Hostname | `hostnamectl set-hostname shoplite-web01` | Names the server |
| Packages | `apt-get install -y nginx git ufw fail2ban unattended-upgrades cron openssh-server` | Installs everything needed. `DEBIAN_FRONTEND=noninteractive` stops apt asking questions |
| Admin user | `useradd -m -s /bin/bash deploy`, `usermod -aG sudo deploy` | A named admin account with sudo, so nobody works as root. `-m` creates the home folder, `-aG` appends to the sudo group |
| Sudoers file | `/etc/sudoers.d/90-deploy`, `chmod 440` | Lets `deploy` use sudo without a password prompt (needed for automation) |
| SSH key | `ssh-keygen -t ed25519 -N ""`, public key into `/home/deploy/.ssh/authorized_keys`, `chmod 700` on `.ssh`, `chmod 600` on the file | Key-based login. SSH ignores key files that are too open |
| SSH hardening | See below | Disables root login and password login |
| Firewall | `ufw default deny incoming`, `ufw default allow outgoing`, `ufw allow 22/tcp`, `80/tcp`, `443/tcp`, `ufw --force enable` | Blocks everything except SSH, HTTP and HTTPS. `--force` skips the confirmation prompt |
| fail2ban | `/etc/fail2ban/jail.local` with `[sshd] enabled = true`, `maxretry = 5`, `bantime = 600` | Bans an IP for 10 minutes after 5 failed SSH logins. This automates what a failed-login log pipeline finds manually |
| Auto updates | `/etc/apt/apt.conf.d/20auto-upgrades` | Security patches install themselves |
| Get the repo | `git clone` (or `git pull`) into `/opt/shoplite` | Brings in the scripts and site; safe to run twice |
| Deploy | `rm -f .../sites-enabled/default`, `SKIP_PULL=1 deploy.sh` | Puts the site live using the tested deploy script |
| Logs, logrotate, cron | `mkdir -p /var/log/shoplite /var/backups/shoplite`, copy logrotate file, `crontab crontab.txt` | Starts monitoring and backups |
| Summary | `ufw status`, `systemctl is-active nginx fail2ban cron`, `curl -sI http://localhost` | Prints the result at the end |

Most `systemctl` calls fall back to `service ...` because some playgrounds do not run systemd the same way.

**Why the key is created before passwords are disabled:** otherwise the admin would be locked out of the server.

#### SSH hardening problem and fix

The requirement is `PermitRootLogin no` and `PasswordAuthentication no`. A simple `sed` on `/etc/ssh/sshd_config` did not work, because:

- Ubuntu cloud images add drop-in files in `/etc/ssh/sshd_config.d/` (for example `50-cloud-init.conf` with `PasswordAuthentication yes`).
- sshd uses the **first** value it finds for an option, and the main file had no such line for `sed` to change.

The fix in `bootstrap.sh`:

```bash
for f in /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf; do
    [ -f "$f" ] && sed -i '/^[[:space:]]*#\?[[:space:]]*PasswordAuthentication/Id; /^[[:space:]]*#\?[[:space:]]*PermitRootLogin/Id' "$f"
done
printf 'PermitRootLogin no\nPasswordAuthentication no\n' > /etc/ssh/sshd_config.d/00-hardening.conf
printf 'PermitRootLogin no\nPasswordAuthentication no\n' | cat - /etc/ssh/sshd_config > /tmp/sshd_config.new
cat /tmp/sshd_config.new > /etc/ssh/sshd_config
sshd -t && systemctl restart ssh
```

| Command | Meaning |
|---|---|
| `sed -i '/pattern/Id'` | Deletes every matching line (also commented ones, any capitalisation) in place |
| `printf ... > 00-hardening.conf` | Writes our two settings into a drop-in file |
| `printf ... \| cat - sshd_config` | Places our two settings at the very top of the main file so they are read first |
| `sshd -t` | Tests the SSH config before restarting, so a typo cannot lock anyone out |
| `sshd -T \| grep -Ei "..."` | Prints the settings sshd actually uses; both now show `no` |

---

## 5. Linux skills used

| Skill | Where it was used |
|---|---|
| Files, `cp`, `mkdir`, symlinks | Setting up Nginx and the repo layout |
| Users, groups, permissions (`useradd`, `usermod -aG`, `chown`, `chmod`) | The `deploy` user and site file ownership |
| `grep`, `awk`, `sort`, `uniq`, `wc` | `log_report.sh`, `health_check.sh` |
| `systemctl`, `journalctl`, `apt` | Nginx and service management |
| `ss`, `curl`, `df`, `free`, SSH keys, `tar` | Health check, backup, security |
| Redirection (`>>`, `2>&1`) and pipes | Cron jobs and every script |
| Bash (variables, `if`, `for`, functions, exit codes) and cron | All the scripts and scheduling |

---

## 6. Day-to-day operations (runbook)

### Deploy a site update

Edit `project/site/index.html`, push to GitHub, then on the server:

```bash
/opt/shoplite/project/scripts/deploy.sh
curl -I http://localhost
```

### Restore from backup

```bash
ls -1t /var/backups/shoplite/                                   # newest first
tar -xzf /var/backups/shoplite/<backup>.tar.gz -C / var/www/shoplite/index.html   # one file
tar -xzf /var/backups/shoplite/<backup>.tar.gz -C /             # everything
systemctl reload nginx
```

### Read the logs

```bash
tail -20 /var/log/shoplite/health.log
grep ALERT /var/log/shoplite/health.log
/opt/shoplite/project/scripts/log_report.sh
journalctl -u nginx -n 50
```

### Troubleshooting

| Symptom | Check |
|---|---|
| Site not loading | `systemctl status nginx`, `nginx -t`, `ss -tulpn \| grep :80`, `ufw status` |
| 403 Forbidden | Missing `index.html` or wrong permissions: `ls -l /var/www/shoplite` |
| Nginx keeps failing | `journalctl -u nginx -n 50`, `tail /var/log/nginx/error.log` |
| Health alerts | `grep ALERT /var/log/shoplite/health.log` |
| Disk filling up | `df -h`, then `du -sh /var/* \| sort -h \| tail` |
| Cron not running | `service cron status`, `crontab -l` |
| Cannot log in over SSH | Use the `deploy` user with `/root/deploy_key`; root login and passwords are disabled by design |
| Many failed logins | `fail2ban-client status sshd` |

---

## 7. Failure tests

| Test | Command | Result |
|---|---|---|
| Nginx stopped | `systemctl stop nginx`, run `health_check.sh` | `ALERT nginx is DOWN`, then `FIXED`, site back to 200 |
| Deleted site file | `rm /var/www/shoplite/index.html`, restore with `tar -xzf ...` | 403, then 200 OK |
| Bad Nginx config | Add `bad_directive on;`, run `deploy.sh` | `nginx -t FAILED`, rollback, site stayed 200 |
| Disk alert | `fallocate -l 2G /tmp/bigfile`, then `DISK_THRESHOLD=0 health_check.sh`, check `grep ALERT /var/log/shoplite/health.log`, then `rm /tmp/bigfile` | `ALERT disk above ...` logged. The threshold is lowered only because the test disk is very large; the real default is 80 |

---

## 8. Screenshots

| File | Shows |
|---|---|
| `screenshots/security-and-cron.png` | UFW active (22/80/443), fail2ban `sshd` jail, three cron jobs |
| `screenshots/health-autorestart.png` | Nginx stopped, health check logs ALERT then FIXED |
| `screenshots/ssh-hardening.png` | `permitrootlogin no` and `passwordauthentication no` |
| `screenshots/backup-delete-403.png` | Backup created, `index.html` deleted, site returns 403 |
| `screenshots/backup-restore-200.png` | File restored from backup, site returns 200 OK |

---

## 9. Possible improvements

- HTTPS with Let's Encrypt (port 443 is already open)
- Email or Slack alerts instead of only log lines
- Central monitoring (Prometheus and Grafana)
- Configuration management such as Ansible instead of one shell script
- Off-server backups (for example object storage)
