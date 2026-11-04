# Linux Fundamentals: Notes

## Block 1: Files and navigation

### Navigation and files

| Command | What it does |
|---|---|
| `pwd` | Prints the current directory. |
| `ls -la` | Lists all files (including hidden) with permissions, owner and size. First character: `-` file, `d` directory, `l` symlink. |
| `cd /etc` | Moves into `/etc` (absolute path). |
| `cd -` | Jumps back to the previous directory and prints it. |
| `cd ..` | Moves up one level to the parent directory. |
| `cd` (no argument) | Goes to the home directory (`~`) from anywhere. |
| `~` and `/` | `~` is home (`/root` for root); `/` is the top of the filesystem tree. |
| `apt update && apt install -y tree` | Refreshes the package list, then installs `tree`. |
| `mkdir -p ~/devops/{app,logs,backup,scripts}` | Creates the folder and all four subfolders in one command. |
| `tree ~/devops` | Shows the folder structure as a tree. |
| `touch app/index.html logs/app.log` | Creates empty files. |
| `cp app/index.html backup/index.html.bak` | Copies a file; the original stays. |
| `mv logs/app.log logs/old.log` | Moves or renames; the original name is gone. |
| `cp -r app backup/app_copy` | Copies a whole folder with its contents (`-r` = recursive). |
| `rm backup/index.html.bak` | Deletes a file permanently (no recycle bin). |
| `rm -i file` | Asks for confirmation before deleting. |

### Symlinks

| Command | What it does |
|---|---|
| `ln -s ~/devops/app app_link` | Creates a symlink (shortcut) to the `app` folder. Shows as `lrwxrwxrwx` with `app_link -> /root/devops/app`; the link's own permissions are ignored. |
| `rm app_link` | Deletes only the link, not the target (no trailing slash). |
| `ln -s /etc/nginx/sites-available/shoplite /etc/nginx/sites-enabled/shoplite` | Used to enable an Nginx site. |

Symlink vs hard link: a symlink points to a path and breaks if the original is deleted; it works on folders. A hard link is another name for the same file data and cannot be used on folders.

`cp` vs `mv`: `cp` leaves the original (two files afterwards), `mv` removes it (one file) and is also how you rename. `cp` needs `-r` for folders.

## Block 2: Viewing and editing files

### Creating and counting

| Command | What it does |
|---|---|
| `cd ~/devops/logs` | Moves into the logs folder. |
| `seq 1 50 > sample.log` | `seq` prints 1 to 50, one per line; `>` redirects it into `sample.log` (overwrites if it exists). |
| `seq 1 200 > big.log` | Same with 200 lines, too long for one screen. |
| `wc -l sample.log` | Counts lines (`-w` words, `-c` bytes). Output: `50 sample.log`. |

### Viewing files

| Command | What it does |
|---|---|
| `cat sample.log` | Prints the whole file. |
| `head sample.log` | First 10 lines (default). |
| `head -n 5 sample.log` | First 5 lines. |
| `tail sample.log` | Last 10 lines (default); useful for logs. |
| `tail -n 5 sample.log` | Last 5 lines. |
| `head -n 25 sample.log \| tail -n 11` | Lines 15 to 25. Formula for lines A to B: `head -n B file \| tail -n (B-A+1)`. |
| `sed -n '15,25p' sample.log` | Another way to print lines 15 to 25. |
| `less big.log` | Scrollable read-only viewer. Keys: Space/`b` page, `G`/`g` end/start, `/text` search, `n`/`N` next/previous match, `&text` filter, `&` clear filter, `q` quit. |

### Redirection and pipes

| Command | What it does |
|---|---|
| `echo "first line" > app.log` | Writes text to a file; `>` overwrites or creates. |
| `echo "second line" >> app.log` | `>>` appends to the end. |
| `cat app.log` | Shows the file contents. |
| `cat sample.log \| grep 5` | Pipe `\|` sends one command's output into the next. |
| `cat sample.log \| wc -l` | Counts the piped lines (50). |
| `ls ~/devops \| wc -l` | Counts items in the folder. |
| `grep "15" big.log \| less` | Filters with grep, then pages the result. |
| `ls /nonexistent > out.log 2>&1` | `>` sends normal output (stream 1) to the file; `2>&1` sends errors (stream 2) to the same place. |

`>` overwrites, `>>` appends. Both create the file if it does not exist.

### Watching a log live (tail -f task)

| Command | What it does |
|---|---|
| `tail -f ~/devops/logs/app.log` | Terminal 2: shows the last 10 lines, then prints new lines as they are added. Ctrl+C stops it. |
| `for i in $(seq 1 20); do echo "log line $i" >> ~/devops/logs/app.log; sleep 1; done` | Terminal 1: appends one line per second, 20 times, simulating an application log. |

### Editing files

| Command | What it does |
|---|---|
| `nano ~/devops/app/index.html` | Beginner-friendly editor. `Ctrl+O` then Enter saves, `Ctrl+X` exits. |
| `vim ~/devops/app/index.html` | Modal editor. `i` insert, `Esc` leave insert mode, `:wq` save and quit, `:q!` quit without saving. |

nano is easy and you can type immediately. vim has modes and is harder to learn, but faster for experts and often the only editor on minimal servers.

## Block 3: Users, groups and permissions

### Creating users and groups

| Command | What it does |
|---|---|
| `groupadd devteam` | Creates the group `devteam`. |
| `useradd -m -s /bin/bash dev1` | Creates user `dev1`. `-m` creates the home folder, `-s` sets the login shell. Repeated for `dev2`. |
| `usermod -aG devteam dev1` | Adds `dev1` to `devteam`. `-G` = supplementary groups, `-a` = append. Without `-a` the user loses all other groups. Capital `-G` is supplementary, small `-g` is primary group. |
| `id dev1` | Shows UID, primary GID and all groups. |
| `groups dev2` | Lists a user's groups. |
| `getent group devteam` | Shows the group and its members. |

### Shared folder and permissions

| Command | What it does |
|---|---|
| `mkdir -p /opt/devops/app` | Creates the shared folder (`/opt` is used because home folders on Ubuntu are private). |
| `chown root:devteam /opt/devops/app` | Owner `root`, group `devteam`. |
| `chmod 775 /opt/devops/app` | Owner and group get `rwx`, others `r-x`. |
| `ls -ld /opt/devops/app` | Shows the folder's own permissions. Result: `drwxrwxr-x root devteam`. |
| `sudo -u dev1 touch /opt/devops/app/dev1.txt` | Runs a command as another user to test access. Works because `dev1` is in `devteam`. |
| `gpasswd -a dev2 devteam` | Adds a user to a group. |
| `gpasswd -d dev2 devteam` | Removes a user from a group. If not a member it prints "not a member", which is harmless. |
| `sudo -u dev2 touch /opt/devops/app/blocked.txt` | After removal from `devteam`, gives `Permission denied`. |

**Proof:** `touch: cannot touch '/opt/devops/app/blocked.txt': Permission denied`. `dev2` now falls under "others" (`r-x`), which has no write permission.

`usermod -aG` changes the **user** (gives the group badge). `chmod`/`chown` change the **folder** (the door rule). Both are needed.

### chmod and chown on files

| Command | What it does |
|---|---|
| `touch script.sh file` | Creates practice files (chmod needs files that exist). |
| `ls -l file` | Shows permission string, owner and group. |
| `chmod u+x script.sh` | Symbolic: adds execute for the owner. |
| `chmod g+w file` / `chmod g-w file` | Adds / removes group write. |
| `chmod 644 file` | Numeric: sets all three classes at once (`rw-r--r--`); replaces earlier settings. |
| `chmod 640 file` | Sets `rw-r-----`: owner read/write, group read, others nothing. |
| `chmod u=rw,g=r,o= file` | Symbolic form of 640. |
| `chown dev1:devteam file` | Changes owner to `dev1` and group to `devteam`. |

Numeric values: `r`=4, `w`=2, `x`=1, added per class (owner, group, others). Symbolic: `u/g/o/a` = owner/group/others/all, `+/-/=` = add/remove/set exactly. Use one style per command.

### Permissions in words

| Mode | Breakdown | Meaning |
|---|---|---|
| `755` | `rwx r-x r-x` | Owner can read, write, execute. Group and others can read and execute. Typical for scripts and folders. |
| `640` | `rw- r-- ---` | Owner can read and write. Group can read. Others have no access. Typical for config files with secrets. |
| `775` | `rwx rwx r-x` | Owner and group can write. Others can read and enter. |

Reading a permission string: `-rw-r-----` is owner `rw-` (6), group `r--` (4), others `---` (0), so the mode is **640**.

### Inspecting users and groups

| Command | What it does |
|---|---|
| `whoami` | Prints the current username. |
| `id` | Shows your UID, GID and groups. |
| `groups` | Lists your groups. |
| `sudo -l` | Lists what the current user may run with sudo. |
| `grep dev /etc/passwd` | Format `name:x:UID:GID:comment:home:shell`. Shows `dev1`, `dev2`. |
| `grep devteam /etc/group` | Format `name:x:GID:members`. |

## Block 4: Text processing

### Sample logs

| Command | What it does |
|---|---|
| `cat > access.log <<'EOF' ... EOF` | Creates a file from the text between the `EOF` markers (here document). Used for a sample web log. |
| `cat > auth_sample.log <<'EOF' ... EOF` | Same for a sample SSH log, because `/var/log/auth.log` may not exist on WSL. |
| `wc -l access.log` | Counts lines in the file. |

### grep

| Command | What it does |
|---|---|
| `grep "404" access.log` | Prints lines containing the text. |
| `grep -c "404" access.log` | Prints the count of matching lines. |
| `grep -i "get" access.log` | Ignores upper/lower case. |
| `grep -v "200" access.log` | Inverts: lines that do NOT match. |
| `grep -n "500" access.log` | Shows line numbers. |
| `grep -rin "error" /var/log` | Recursive, case-insensitive, with line numbers. |

### awk

awk splits each line into fields on whitespace: `$1` is field 1, `NF` is the number of fields.

| Command | What it does |
|---|---|
| `awk '{print $1}' access.log` | Prints field 1 (IP address). |
| `awk '{print $7}' access.log` | Prints field 7 (requested page). |
| `awk '{print $9}' access.log` | Prints field 9 (status code). |
| `awk '$9 >= 400' access.log` | Lines where the status code is 400 or higher. |
| `awk '{print $(NF-3)}' file` | Prints the 4th field from the end; works even if a line has extra words at the start. |

### sort, uniq, cut

| Command | What it does |
|---|---|
| `sort` | Sorts lines so identical ones are adjacent. |
| `uniq -c` | Collapses adjacent duplicates and prefixes a count. Needs sorted input. |
| `sort -nr` | `-n` numeric, `-r` reverse (highest first). |
| `head -5` | Keeps the top 5 lines. |
| `cut -d' ' -f1 access.log` | Cuts field 1 using a space delimiter. |

Top IPs pipeline: `awk '{print $1}' access.log | sort | uniq -c | sort -nr | head -5`. awk extracts the IP, sort groups, uniq -c counts, sort -nr ranks, head -5 keeps five. With `$7` it gives top pages, with `$9` status code counts.

### Task: top 5 IPs with failed logins

| Command | What it does |
|---|---|
| `ls -l /var/log/auth.log` | Checks whether the real auth log exists. |
| `grep "Failed password" auth_sample.log \| awk '{print $(NF-3)}' \| sort \| uniq -c \| sort -nr \| head -5` | grep keeps failures, awk takes the IP, sort groups, uniq -c counts, sort -nr ranks, head -5 keeps the top five. |
| `grep -c "Failed password" auth_sample.log` | Total number of failed logins. |

### find

| Command | What it does |
|---|---|
| `find / -name "*.conf" -size +10k 2>/dev/null` | Finds files by name and size; `2>/dev/null` hides permission errors. |
| `find ~/devops -type f` | Only files. |
| `find ~/devops -name "*.log"` | By name pattern. |
| `find / -size +100M 2>/dev/null` | Files over 100 MB. |

### sed

| Command | What it does |
|---|---|
| `sed 's/old/new/g' test.txt` | Prints text with `old` replaced by `new`; file unchanged. s = substitute, g = every match on the line. |
| `sed -i 's/old/new/g' test.txt` | `-i` edits the file in place. |
| `sed -n '15,25p' file` | Prints only lines 15 to 25. |

## Block 5: Processes, services and packages

### Processes

| Command | What it does |
|---|---|
| `ps` | Process status: lists processes in the current terminal. |
| `ps aux` | All processes from all users: `a` all users, `u` user format, `x` include non-terminal processes. |
| `ps -p 1 -o comm=` | `-p 1` selects PID 1, `-o comm=` prints only the command name. `systemd` means `systemctl` works. |
| `sleep 300 &` | Runs a command in the background. |
| `jobs` | Lists background jobs of the current shell. |
| `ps aux \| grep "sleep 300"` | Finds the process and its PID (second column). |
| `kill <PID>` | Sends SIGTERM (15): a polite request, the process can clean up. |
| `kill -9 <PID>` | Sends SIGKILL: stops it immediately, no cleanup. Last resort. |
| `kill -9 $!` | `$!` is the PID of the last background job. |
| `top` | Live view of processes and resource use; `q` to quit. |

### Packages (apt)

| Command | What it does |
|---|---|
| `apt update` | Refreshes the package list. |
| `apt install -y nginx` | Installs Nginx; `-y` answers yes. |
| `nginx -v` | Shows the Nginx version. |
| `apt list --installed \| grep nginx` | Checks if a package is installed. |
| `apt remove -y tree` | Removes a package. |

### Services (systemctl)

| Command | What it does |
|---|---|
| `systemctl start nginx` | Starts the service now. |
| `systemctl status nginx` | Shows state (`active (running)`) and recent logs; `q` exits the pager. |
| `systemctl status nginx --no-pager` | Shows status without the pager. |
| `systemctl enable nginx` | Starts the service automatically on boot. |
| `systemctl stop nginx` | Stops the service. |
| `systemctl restart nginx` | Stops then starts (brief downtime). |
| `systemctl reload nginx` | Re-reads config without stopping (no downtime). |
| `systemctl is-active nginx` | Prints `active` or `inactive`; used in scripts. |
| `systemctl is-enabled nginx` | Prints `enabled` or `disabled`. |
| `curl -I http://localhost` | Headers only; `HTTP/1.1 200 OK` means the web server works. |
| `curl -s -o /dev/null -w "%{http_code}" http://localhost` | Prints only the HTTP status code; used in scripts. |

`restart` stops and starts the service, so connections drop briefly. `reload` applies a changed config while the service keeps running.

### Logs (journalctl)

| Command | What it does |
|---|---|
| `journalctl -u nginx --since "10 min ago"` | Nginx logs from the last 10 minutes. |
| `journalctl -u nginx -n 20` | Last 20 log lines. |
| `journalctl -u nginx -f` | Follows logs live; Ctrl+C to stop. |

## Block 6: Networking and disk basics

### Networking

| Command | What it does |
|---|---|
| `ip a` | Shows interfaces and IP addresses (`a` = `address`, a subcommand, not a flag). `lo` is loopback (127.0.0.1), `inet` is the IPv4 address. |
| `ip -br a` | Brief one-line-per-interface view. |
| `ping -c 4 google.com` | Sends 4 test packets; `-c` = count (Linux ping runs forever without it). |
| `ping -c 2 8.8.8.8` | Tests the internet by IP, without DNS. If this works but a hostname fails, DNS is the problem. |
| `cat /etc/hosts` | Local name-to-IP mappings, checked before DNS. |
| `echo "127.0.0.1 shoplite.local" >> /etc/hosts` | Adds a custom name (use `>>` so existing entries stay). |
| `curl http://localhost` | Fetches the page and prints the body. |
| `curl -I http://localhost` | Headers only; shows the status code. |
| `curl -L URL` / `curl -m 5 URL` | Follow redirects / time out after 5 seconds. |
| `ss -tulpn` | Listening ports: `-t` TCP, `-u` UDP, `-l` listening, `-p` process, `-n` numeric. |
| `ss -tulpn \| grep :80` | Finds which process uses port 80; nginx listens on 80. |

### Disk and memory

| Command | What it does |
|---|---|
| `df -h` | Disk usage per filesystem (fuel gauge); `Use%` is the column to watch. |
| `du -sh /var/*` | Size of each item in /var; `-s` summary, `-h` human readable. |
| `du -sh /var/* \| sort -h \| tail -5` | The 5 biggest items (tracing a full disk). |
| `free -h` | Memory usage; "available" is what programs can still use. |

`df` shows how full the disk is, `du` shows what is using the space. Use df to detect, du to find the cause.

Tracing a full disk, in order: `df -h`, then `du -sh /* | sort -h`, repeat `du` inside the biggest folder, then `find / -size +100M`.

### SSH keys

| Command | What it does |
|---|---|
| `apt install -y openssh-server` | Installs the SSH server. |
| `systemctl start ssh` | Starts the SSH service (called `ssh` on Ubuntu). |
| `ssh-keygen -t ed25519` | Creates a key pair. `-t` sets the type (ed25519 recommended; rsa with `-b 4096` for old systems). Private key stays secret, public key (`.pub`) goes on servers. |
| `ls -l ~/.ssh` | Lists the key files and permissions. |
| `cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys` | Appends the public key to the list of keys allowed to log in. |
| `chmod 600 ~/.ssh/authorized_keys` | Owner-only read/write; SSH ignores the file if it is too open. |
| `ssh -o StrictHostKeyChecking=no localhost` | Logged in with no password, so key login works. The option skips the first-connection prompt. |
| `ssh -v localhost exit` | Verbose mode; `Authenticated ... using "publickey"` proves the key was used. |
| `ssh user@host` | Logs in to another machine; `ssh-copy-id user@host` installs your key there. |
| `exit` | Closes the SSH session. |

Passwords can be brute-forced, keys cannot. In production set `PasswordAuthentication no` and `PermitRootLogin no`.

### tar

| Command | What it does |
|---|---|
| `tar -czvf ~/backup.tar.gz ~/devops` | Creates a gzip archive: c create, z gzip, v verbose, f file name. Create it outside the folder being archived. |
| `tar -tzf backup.tar.gz \| head` | Lists contents without extracting. |
| `tar -xzvf backup.tar.gz -C /tmp` | Extracts into /tmp (`-C` = target directory). |
| `tar -xzvf backup.tar.gz -C /tmp root/devops/app/index.html` | Extracts a single file, used to restore a deleted file. |

A tarball is one file bundling many files and folders (tape archive); `.gz` means it is also compressed.

## Block 7: Bash scripting and cron

### Bash script

A bash script is a text file of commands run in order, with variables, conditions and loops. It needs `#!/bin/bash` on line 1 and `chmod +x`.

| Command | What it does |
|---|---|
| `#!/bin/bash` | Shebang: must be the first line; tells the system to run the file with bash. |
| `HOSTNAME=$(hostname)` | Stores a command's output in a variable (no spaces around `=`). |
| `uptime -p` | Shows how long the system has been running, readable form. |
| `df -h / \| awk 'NR==2 {print $5}' \| tr -d '%'` | Root disk Use% as a plain number: line 2 only, column 5, `%` removed. |
| `free \| awk '/Mem:/ {printf "%.0f", $3/$2*100}'` | Memory used as a percentage: used / total * 100. |
| `${DISK}%` | Braces mark where the variable name ends. |
| `if [ "$DISK" -gt 80 ]; then ... else ... fi` | Condition; `-gt` greater than; `fi` closes the block. |
| `for svc in nginx ssh; do ... done` | Loops over a list. |
| `systemctl is-active --quiet nginx` | Exit code 0 if active; used inside `if`. |
| `chmod +x health.sh` | Makes the script executable. |
| `~/devops/scripts/health.sh` | Absolute path: works from any directory. Cron must use absolute paths. |
| `bash health.sh` | Runs the script through bash without needing `chmod +x`. |
| `echo $?` | Exit code of the last command: 0 success, non-zero failure (1 error or no match, 127 command not found). Run it immediately after the command. |
| `exit 0` / `exit 1` | Ends a script returning success / failure. |

### health.sh

```bash
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
```
### cron

Cron is the Linux scheduler: a background service that runs commands at set times. Jobs are stored in a crontab.

| Command | What it does |
|---|---|
| `crontab -e` | Edits your cron jobs. |
| `crontab -l` | Lists your cron jobs. |
| `crontab -r` | Removes all your cron jobs. |
| `echo '...' \| crontab -` | Replaces the crontab with the piped line. |
| `*/5 * * * * /root/devops/scripts/health.sh >> /root/devops/logs/health.log 2>&1` | Every 5 minutes: runs the script, appends output and errors to a log. |
| `service cron status` | Checks that the cron service is running. |

Format: `minute hour day-of-month month day-of-week command`.

| Expression | Meaning |
|---|---|
| `*/5 * * * *` | Every 5 minutes |
| `0 1 * * *` | Daily at 01:00 |
| `0 8 * * *` | Daily at 08:00 |
| `30 2 * * 1` | Every Monday at 02:30 |

## Quiz answers

**1. What is the difference between `/etc`, `/var` and `/opt`?**

`/etc` holds configuration files. `/var` holds data that changes at runtime, such as logs, caches and backups. `/opt` holds optional third-party software (I cloned the project to `/opt/shoplite`).

**2. A file shows `-rw-r-----`. Who can read it, and what is its numeric mode?**

The owner can read and write, and the group can read. Others have no access. The mode is 640.

**3. How do you find which process is using port 80?**

`ss -tulpn | grep :80` (or `lsof -i :80`).

**4. What is the difference between `systemctl restart` and `systemctl reload`?**

`restart` stops and starts the service, so connections drop briefly. `reload` re-reads the config without stopping, so there is no downtime.

**5. How would you find all files over 100 MB on the server?**

`find / -size +100M 2>/dev/null`

**6. What does `2>&1` do in `command > out.log 2>&1`?**

It sends errors (stream 2) to the same place as normal output (stream 1), so both end up in `out.log`.

**7. Write the cron expression for "every Monday at 02:30".**

`30 2 * * 1`

**8. A disk is 95% full. List the commands you would run, in order, to find the cause.**

1. `df -h` to find the full filesystem.
2. `du -sh /* 2>/dev/null | sort -h | tail -5` to find the biggest folders.
3. Repeat `du` inside the biggest folder to drill down.
4. `find / -size +100M 2>/dev/null` to find large files.
5. `ls -lh /var/log` to check logs, then delete, rotate or move what is not needed.

**9. Why should SSH password login be disabled on a production server?**

Passwords can be brute-forced, leaked or reused. Keys cannot be guessed, so with `PasswordAuthentication no` only holders of an authorized private key can log in.

**10. What is the difference between a process being killed with `kill` and `kill -9`?**

`kill` sends SIGTERM (15), a polite request that lets the process clean up. `kill -9` sends SIGKILL, which stops it immediately with no cleanup. Use it as a last resort.
