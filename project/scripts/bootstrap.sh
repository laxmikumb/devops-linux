#!/bin/bash
# bootstrap.sh: rebuilds the ShopLite server on a fresh Ubuntu machine.
# Run as root: git clone <repo> /opt/shoplite && bash /opt/shoplite/project/scripts/bootstrap.sh
set -u

REPO_URL=${REPO_URL:-https://github.com/laxmikumb/devops-linux.git}
APP_DIR=/opt/shoplite
ADMIN=deploy
PUBKEY_FILE=${PUBKEY_FILE:-}     # optional: public key file for the deploy user

log() { echo "[bootstrap] $1"; }

[ "$(id -u)" -eq 0 ] || { echo "Run as root"; exit 1; }
export DEBIAN_FRONTEND=noninteractive

# 1. Hostname
log "setting hostname"
hostnamectl set-hostname shoplite-web01 2>/dev/null || hostname shoplite-web01

# 2. Packages
log "installing packages"
apt-get update -y
apt-get install -y nginx git ufw fail2ban unattended-upgrades cron openssh-server

# 3. Admin user with sudo and key-based SSH
log "creating user $ADMIN"
id "$ADMIN" >/dev/null 2>&1 || useradd -m -s /bin/bash "$ADMIN"
usermod -aG sudo "$ADMIN"
echo "$ADMIN ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-$ADMIN
chmod 440 /etc/sudoers.d/90-$ADMIN
install -d -m 700 -o "$ADMIN" -g "$ADMIN" /home/$ADMIN/.ssh
if [ -n "$PUBKEY_FILE" ] && [ -f "$PUBKEY_FILE" ]; then
    cat "$PUBKEY_FILE" >> /home/$ADMIN/.ssh/authorized_keys
elif [ ! -f /home/$ADMIN/.ssh/authorized_keys ]; then
    ssh-keygen -t ed25519 -N "" -f /root/deploy_key -q
    cat /root/deploy_key.pub >> /home/$ADMIN/.ssh/authorized_keys
    log "generated key pair: /root/deploy_key (use it to log in as $ADMIN)"
fi
chown "$ADMIN:$ADMIN" /home/$ADMIN/.ssh/authorized_keys
chmod 600 /home/$ADMIN/.ssh/authorized_keys

# 4. SSH hardening (only after the key is in place)
log "hardening sshd"
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
mkdir -p /run/sshd
if sshd -t; then
    systemctl restart ssh 2>/dev/null || service ssh restart
else
    log "sshd config test FAILED, not restarting"
fi

# 5. Firewall
log "configuring ufw"
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# 6. fail2ban for SSH
log "enabling fail2ban"
cat > /etc/fail2ban/jail.local <<'EOF'
[sshd]
enabled = true
maxretry = 5
bantime = 600
EOF
systemctl enable --now fail2ban 2>/dev/null || service fail2ban restart

# 7. Automatic security updates
log "enabling unattended-upgrades"
printf 'APT::Periodic::Update-Package-Lists "1";\nAPT::Periodic::Unattended-Upgrade "1";\n' > /etc/apt/apt.conf.d/20auto-upgrades
systemctl enable --now unattended-upgrades 2>/dev/null || true

# 8. Get the repo
log "getting repo in $APP_DIR"
if [ -d "$APP_DIR/.git" ]; then
    git -C "$APP_DIR" pull --ff-only
else
    git clone "$REPO_URL" "$APP_DIR"
fi
chmod +x "$APP_DIR"/project/scripts/*.sh

# 9. Deploy site (deploy.sh copies site, installs nginx config, tests, reloads)
log "deploying site"
rm -f /etc/nginx/sites-enabled/default
SKIP_PULL=1 "$APP_DIR/project/scripts/deploy.sh"
systemctl enable --now nginx 2>/dev/null || service nginx start

# 10. Logs, logrotate, cron
log "installing logrotate and cron"
mkdir -p /var/log/shoplite /var/backups/shoplite
cp "$APP_DIR/project/configs/logrotate-shoplite" /etc/logrotate.d/shoplite
crontab "$APP_DIR/project/configs/crontab.txt"
systemctl enable --now cron 2>/dev/null || service cron start

# 11. Summary
log "done. Status:"
ufw status | head -8
systemctl is-active nginx fail2ban cron 2>/dev/null
curl -sI http://localhost | head -1
