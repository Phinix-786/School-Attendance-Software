#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# App_Name/Domain backend installer
# Run once as root on your Ubuntu server:
#   sudo bash install.sh
#
# What it does:
#   1. Installs Python 3.11, pip, venv, dnsutils, curl
#   2. Creates /opt/App_Name/Domain/ with virtualenv + app files
#   3. Creates upload dir  /var/App_Name/Domain/uploads
#   4. Writes /etc/App_Name/Domain.env  (you fill in tokens/keys here)
#   5. Installs three systemd units:
#        your-domain-duckdns.service + .timer  (update DuckDNS every 5 min)
#        App_Name/Domain-backend.service           (uvicorn, starts on boot)
#   6. Enables & starts everything
# ─────────────────────────────────────────────────────────────
set -euo pipefail
[[ $EUID -ne 0 ]] && { echo "Run as root (sudo bash install.sh)"; exit 1; }

INSTALL_DIR="/opt/App_Name/Domain"
UPLOAD_DIR="/var/App_Name/Domain/uploads"
ENV_FILE="/etc/App_Name/Domain.env"
SERVICE_USER="App_Name/Domain"

echo "=== 1. System packages ==="
apt-get update -q
apt-get install -y python3.11 python3.11-venv python3-pip dnsutils curl ufw

echo "=== 2. Service user ==="
id -u "$SERVICE_USER" &>/dev/null || useradd -r -s /usr/sbin/nologin "$SERVICE_USER"

echo "=== 3. Install dir ==="
mkdir -p "$INSTALL_DIR"
cp main.py requirements.txt duckdns_update.sh "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/duckdns_update.sh"
chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"

echo "=== 4. Python venv ==="
python3.11 -m venv "$INSTALL_DIR/venv"
"$INSTALL_DIR/venv/bin/pip" install -q --upgrade pip
"$INSTALL_DIR/venv/bin/pip" install -q -r "$INSTALL_DIR/requirements.txt"

echo "=== 5. Upload dir ==="
mkdir -p "$UPLOAD_DIR"
chown -R "$SERVICE_USER:$SERVICE_USER" "$UPLOAD_DIR"

echo "=== 6. Env file ==="
if [[ ! -f "$ENV_FILE" ]]; then
    cat > "$ENV_FILE" <<'EOF'
# your-domain backend environment variables
# Fill in your actual values, then: sudo systemctl restart your-domain-backend

# DuckDNS
DUCKDNS_TOKEN=YOUR_DUCKDNS_TOKEN_HERE
DUCKDNS_DOMAIN=your-domain

# Backend API key — must match kBackendApiKey in flutter apps
App_Name/Domain_API_KEY=CHANGE_THIS_TO_A_LONG_RANDOM_SECRET

# Upload directory (leave as default unless you moved it)
App_Name/Domain_UPLOAD_DIR=/var/your-domain/uploads

# Port the backend listens on (also open in ufw below)
App_Name/Domain_PORT=8000
EOF
    chmod 600 "$ENV_FILE"
    echo "  Created $ENV_FILE — EDIT IT before starting services!"
else
    echo "  $ENV_FILE already exists – skipping"
fi

echo "=== 7. systemd: DuckDNS service ==="
cat > /etc/systemd/system/your-domain-duckdns.service <<EOF
[Unit]
Description=Your Domain DuckDNS updater
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=$SERVICE_USER
EnvironmentFile=$ENV_FILE
ExecStart=$INSTALL_DIR/duckdns_update.sh
StandardOutput=journal
StandardError=journal
EOF

cat > /etc/systemd/system/your-domain-duckdns.timer <<EOF
[Unit]
Description=Run DuckDNS updater every 5 minutes
Requires=your-domain-duckdns.service

[Timer]
OnBootSec=30sec
OnUnitActiveSec=5min
Unit=your-domain-duckdns.service

[Install]
WantedBy=timers.target
EOF

echo "=== 8. systemd: backend service ==="
cat > /etc/systemd/system/your-domain-backend.service <<EOF
[Unit]
Description=Your Domain Image Backend (FastAPI/uvicorn)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR
EnvironmentFile=$ENV_FILE
ExecStart=$INSTALL_DIR/venv/bin/uvicorn main:app --host 0.0.0.0 --port \${App_Name/Domain_PORT:-8000} --workers 2
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "=== 9. Enable & start ==="
systemctl daemon-reload
systemctl enable your-domain-duckdns.timer
systemctl enable your-domain-backend.service
systemctl start  your-domain-duckdns.timer
systemctl start  your-domain-backend.service

echo "=== 10. Firewall: open port 8000 ==="
ufw allow 8000/tcp || true
ufw --force enable  || true

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  NEXT STEPS                                              ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  1. Edit  /etc/your-domain.env  and fill in:              ║"
echo "║       DUCKDNS_TOKEN  – from duckdns.org/install          ║"
echo "║       App_Name/Domain_API_KEY – pick a long random string         ║"
echo "║  2. sudo systemctl restart your-domain-backend                ║"
echo "║  3. sudo systemctl start  your-domain-duckdns                 ║"
echo "║  4. Copy App_Name/Domain_API_KEY into Flutter:                    ║"
echo "║       lib/backend_config.dart  in every app              ║"
echo "║  5. Test:                                                ║"
echo "║       curl -H 'X-API-Key: YOUR_KEY' \\                   ║"
echo "║            http://your-domain.duckdns.org:8000/health         ║"
echo "╚══════════════════════════════════════════════════════════╝"
