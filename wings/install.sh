#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_header() {
    echo -e "\n${MAGENTA}╔══════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}${CYAN}   $1${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════╝${NC}"
}

print_status()  { echo -e "${YELLOW}➤ $1...${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error()   { echo -e "${RED}✗ $1${NC}"; }

pause_return() {
    echo ""
    read -n 1 -s -r -p "  Press any key to return to JAYANTH HUB..."
    echo ""
    exit 0
}

clear
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}${CYAN}     PTERODACTYL WINGS INSTALLER     ${NC}${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
    pause_return
fi

# ── 1. Docker ──────────────────────────────────────
print_header "INSTALLING DOCKER"
if command -v docker &>/dev/null; then
    print_success "Docker already installed — skipping"
else
    print_status "Downloading and installing Docker"
    curl -sSL https://get.docker.com -o /tmp/get-docker.sh
    sh /tmp/get-docker.sh || true
    rm -f /tmp/get-docker.sh
    print_success "Docker installed"
fi

print_status "Enabling Docker service"
systemctl enable --now docker >/dev/null 2>&1 || true
print_success "Docker service enabled"

# ── 2. GRUB (skip if VPS) ──────────────────────────
print_header "SYSTEM UPDATE"
if [ -f "/etc/default/grub" ]; then
    print_status "Updating GRUB swapaccount"
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="swapaccount=1"/' /etc/default/grub || true
    update-grub >/dev/null 2>&1 || true
    print_success "GRUB updated"
else
    print_success "GRUB not found (VPS) — skipped"
fi

# ── 3. Wings binary ───────────────────────────────
print_header "INSTALLING WINGS"
print_status "Creating directories"
mkdir -p /etc/pterodactyl
print_success "Directories ready"

ARCH=$(uname -m)
[ "$ARCH" = "x86_64" ] && ARCH="amd64" || ARCH="arm64"
print_status "Downloading Wings ($ARCH)"

WINGS_URL="https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_${ARCH}"
curl -L --retry 3 --retry-delay 2 \
    -o /usr/local/bin/wings \
    "$WINGS_URL"

if [ ! -s /usr/local/bin/wings ]; then
    print_error "Wings download failed or file is empty"
    pause_return
fi

chmod u+x /usr/local/bin/wings
print_success "Wings downloaded and permissions set"

# ── 4. systemd service ────────────────────────────
print_header "CONFIGURING SERVICE"
cat > /etc/systemd/system/wings.service << 'EOF'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload >/dev/null 2>&1 || true
systemctl enable wings >/dev/null 2>&1 || true
print_success "Wings service configured and enabled"

# ── 5. SSL cert ───────────────────────────────────
print_header "GENERATING SSL"
mkdir -p /etc/certs/wing && cd /etc/certs/wing
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=NA/ST=NA/L=NA/O=NA/CN=Generic SSL Certificate" \
    -keyout privkey.pem -out fullchain.pem >/dev/null 2>&1 || true
print_success "SSL certificate generated"

# ── 6. wing helper ────────────────────────────────
print_header "HELPER COMMAND"
cat > /usr/local/bin/wing << 'EOF'
#!/bin/bash
echo -e "\033[1;33mℹ️  Wings Helper\033[0m"
echo -e "\033[1;36mStart:\033[0m    \033[1;32msudo systemctl start wings\033[0m"
echo -e "\033[1;36mStatus:\033[0m   \033[1;32msudo systemctl status wings\033[0m"
echo -e "\033[1;36mLogs:\033[0m     \033[1;32msudo journalctl -u wings -f\033[0m"
EOF
chmod +x /usr/local/bin/wing
print_success "Helper command 'wing' created"

# ── 7. Done ───────────────────────────────────────
print_header "INSTALLATION COMPLETE"
echo -e "${GREEN}🎉 Wings installed successfully!${NC}"
echo ""
echo -e "${YELLOW}📋 NEXT STEPS:${NC}"
echo -e "  ${CYAN}1.${NC} Configure Wings from your panel (Nodes → Deploy)"
echo -e "  ${CYAN}2.${NC} Paste the config into: ${GREEN}/etc/pterodactyl/config.yml${NC}"
echo -e "  ${CYAN}3.${NC} Start Wings: ${GREEN}systemctl start wings${NC}"
echo ""

# ── 8. Auto-configure ─────────────────────────────
read -p "$(echo -e "${YELLOW}Auto-configure Wings now? (y/N): ${NC}")" AUTO_CONFIG
if [[ "$AUTO_CONFIG" =~ ^[Yy]$ ]]; then
    print_header "AUTO-CONFIGURING WINGS"
    echo -e "${YELLOW}Get these values from your panel → Nodes → Deploy:${NC}"
    echo ""
    read -p "$(echo -e "${CYAN}UUID: ${NC}")" UUID
    read -p "$(echo -e "${CYAN}Token ID: ${NC}")" TOKEN_ID
    read -p "$(echo -e "${CYAN}Token: ${NC}")" TOKEN
    read -p "$(echo -e "${CYAN}Panel URL (https://...): ${NC}")" REMOTE

    cat > /etc/pterodactyl/config.yml << CFG
debug: false
uuid: ${UUID}
token_id: ${TOKEN_ID}
token: ${TOKEN}
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: true
    cert: /etc/certs/wing/fullchain.pem
    key: /etc/certs/wing/privkey.pem
  upload_limit: 100
system:
  data: /var/lib/pterodactyl/volumes
  sftp:
    bind_port: 2022
allowed_mounts: []
remote: '${REMOTE}'
CFG
    print_success "Config saved to /etc/pterodactyl/config.yml"

    systemctl start wings
    print_success "Wings service started"
    echo ""
    echo -e "${GREEN}✅ Wings is running!${NC}"
    echo -e "${YELLOW}Logs:${NC} ${GREEN}journalctl -u wings -f${NC}"
else
    echo -e "${YELLOW}Skipped. Configure manually:${NC} ${GREEN}/etc/pterodactyl/config.yml${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}        Thank you for using JAYANTH-hosting!       ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
pause_return
