#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

CHECKMARK="✓"
CROSSMARK="✗"
ARROW="➤"

print_header() {
    echo -e "\n${MAGENTA}╔══════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}${CYAN}   $1${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════╝${NC}"
}

print_status() { echo -e "${YELLOW}${ARROW} $1...${NC}"; }
print_success() { echo -e "${GREEN}${CHECKMARK} $1${NC}"; }
print_error() { echo -e "${RED}${CROSSMARK} $1${NC}"; }

clear
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}${CYAN}     PTERODACTYL WINGS INSTALLER     ${NC}${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"

if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
    exit 1
fi

# ------------------------
# 1. Docker install
# ------------------------
print_header "INSTALLING DOCKER"
print_status "Installing Docker"
curl -sSL https://get.docker.com/ | CHANNEL=stable bash
print_success "Docker installed"

print_status "Starting Docker service"
systemctl enable --now docker > /dev/null 2>&1 || true
print_success "Docker service started"

# ------------------------
# 2. Update GRUB (optional — skip if not available)
# ------------------------
print_header "UPDATING SYSTEM"
GRUB_FILE="/etc/default/grub"
if [ -f "$GRUB_FILE" ]; then
    print_status "Updating GRUB"
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="swapaccount=1"/' "$GRUB_FILE" || true
    update-grub > /dev/null 2>&1 || true
    print_success "GRUB updated"
else
    print_success "GRUB not present (VPS env) — skipped"
fi

# ------------------------
# 3. Wings install
# ------------------------
print_header "INSTALLING WINGS"
print_status "Creating directories"
mkdir -p /etc/pterodactyl
print_success "Directories created"

print_status "Detecting architecture"
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
    ARCH="amd64"
else
    ARCH="arm64"
fi
print_success "Architecture: $ARCH"

print_status "Downloading Wings"
curl -L -o /usr/local/bin/wings \
    "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$ARCH"
print_success "Wings downloaded"

print_status "Setting permissions"
chmod u+x /usr/local/bin/wings
print_success "Permissions set"

# ------------------------
# 4. Wings service
# ------------------------
print_header "CONFIGURING SERVICE"
print_status "Creating service file"
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
print_success "Service file created"

print_status "Reloading systemd"
systemctl daemon-reload > /dev/null 2>&1
print_success "Systemd reloaded"

print_status "Enabling service"
systemctl enable wings > /dev/null 2>&1
print_success "Service enabled"

# ------------------------
# 5. SSL Certificate
# ------------------------
print_header "GENERATING SSL"
print_status "Creating certificate"
mkdir -p /etc/certs/wing
cd /etc/certs/wing || true
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=NA/ST=NA/L=NA/O=NA/CN=Generic SSL Certificate" \
    -keyout privkey.pem -out fullchain.pem > /dev/null 2>&1
print_success "SSL certificate generated"

# ------------------------
# 6. 'wing' helper command
# ------------------------
print_header "CREATING HELPER COMMAND"
cat > /usr/local/bin/wing << 'EOF'
#!/bin/bash
echo -e "\033[1;33mℹ️  Wings Helper Command\033[0m"
echo -e "\033[1;36mTo start Wings, run:\033[0m"
echo -e "    \033[1;32msudo systemctl start wings\033[0m"
echo -e "\033[1;36mTo check Wings status:\033[0m"
echo -e "    \033[1;32msudo systemctl status wings\033[0m"
echo -e "\033[1;36mTo view Wings logs:\033[0m"
echo -e "    \033[1;32msudo journalctl -u wings -f\033[0m"
echo -e "\033[1;33m⚠️  Make sure Node port 8080 → 443 is mapped.\033[0m"
EOF
chmod +x /usr/local/bin/wing
print_success "Helper command created"

# ------------------------
# Installation Complete
# ------------------------
print_header "INSTALLATION COMPLETE"
echo -e "${GREEN}🎉 Wings has been successfully installed!${NC}"
echo -e ""
echo -e "${YELLOW}📋 NEXT STEPS:${NC}"
echo -e "  ${CYAN}1.${NC} Configure Wings with your panel details"
echo -e "  ${CYAN}2.${NC} Start Wings service: ${GREEN}sudo systemctl start wings${NC}"
echo -e "  ${CYAN}3.${NC} Use the helper command: ${GREEN}wing${NC}"
echo -e ""

# ------------------------
# 7. Optional Auto-configure
# ------------------------
echo -e "${YELLOW}🔧 AUTO-CONFIGURATION${NC}"
read -p "$(echo -e "${YELLOW}Do you want to auto-configure Wings now? (y/N): ${NC}")" AUTO_CONFIG

if [[ "$AUTO_CONFIG" =~ ^[Yy]$ ]]; then
    print_header "AUTO-CONFIGURING WINGS"
    echo -e "${YELLOW}Please provide the following details from your Pterodactyl panel:${NC}"
    echo ""
    read -p "$(echo -e "${CYAN}Enter UUID: ${NC}")" UUID
    read -p "$(echo -e "${CYAN}Enter Token ID: ${NC}")" TOKEN_ID
    read -p "$(echo -e "${CYAN}Enter Token: ${NC}")" TOKEN
    read -p "$(echo -e "${CYAN}Enter Panel URL (e.g., https://panel.example.com): ${NC}")" REMOTE

    print_status "Creating Wings configuration"
    mkdir -p /etc/pterodactyl
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
    print_success "Configuration saved to /etc/pterodactyl/config.yml"

    print_status "Starting Wings service"
    systemctl start wings
    print_success "Wings service started"

    echo -e ""
    echo -e "${GREEN}✅ Wings auto-configuration completed!${NC}"
    echo -e "${YELLOW}Check status:${NC} ${GREEN}systemctl status wings${NC}"
    echo -e "${YELLOW}View logs:${NC} ${GREEN}journalctl -u wings -f${NC}"
else
    echo -e "${YELLOW}⚠️  Auto-configuration skipped.${NC}"
    echo -e "${YELLOW}To configure manually, edit:${NC} ${GREEN}/etc/pterodactyl/config.yml${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}           Thank you for using JAYANTH-hosting!   ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -n 1 -s -r -p "Press any key to return to JAYANTH HUB..."

