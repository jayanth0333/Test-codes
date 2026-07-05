#!/usr/bin/env bash

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
P='\033[1;38;5;201m'; VIOLET='\033[1;38;5;135m'; DG='\033[0;38;5;244m'
NC='\033[0m'

tty_read() { read "$@" < /dev/tty; }
print_header() {
    echo -e "\n${MAGENTA}╔══════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC} ${CYAN}  $1${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════╝${NC}"
}
print_step() { echo -e "${YELLOW}➤ $1${NC}"; }
print_ok()   { echo -e "${GREEN}✓ $1${NC}"; }
print_err()  { echo -e "${RED}✗ $1${NC}"; }
pause_return() {
    echo ""
    tty_read -n 1 -s -r -p "  Press any key to return..."
    echo ""; exit 0
}

# ════════════════════════════════════════════════════
# INSTALL
# ════════════════════════════════════════════════════
install_panel() {
    clear
    echo -e "${VIOLET}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${VIOLET}║${NC}        ${P}★ JAYANTH HUB :: PANEL INSTALLER${NC}            ${VIOLET}║${NC}"
    echo -e "${VIOLET}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    [ "$EUID" -ne 0 ] && { print_err "Run as root!"; pause_return; }

    # ── Collect info ─────────────────────────────────
    print_header "CONFIGURATION"

    tty_read -p "$(echo -e "${CYAN}Use IP or Domain? (ip/domain): ${NC}")" CONN_TYPE
    if [[ "$CONN_TYPE" == "domain" ]]; then
        tty_read -p "$(echo -e "${CYAN}Enter domain (e.g. panel.example.com): ${NC}")" FQDN
        USE_SSL="yes"
        PANEL_URL="https://$FQDN"
    else
        FQDN=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
        echo -e "${GREEN}Detected IP: $FQDN${NC}"
        USE_SSL="no"
        PANEL_URL="http://$FQDN"
    fi

    tty_read -p "$(echo -e "${CYAN}Database name [panel]: ${NC}")" DB_NAME;       DB_NAME=${DB_NAME:-panel}
    tty_read -p "$(echo -e "${CYAN}Database username [pterodactyl]: ${NC}")" DB_USER; DB_USER=${DB_USER:-pterodactyl}
    DB_PASS=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 20)
    echo -e "${YELLOW}Auto DB password: ${GREEN}$DB_PASS${NC}"

    tty_read -p "$(echo -e "${CYAN}Admin email: ${NC}")" ADMIN_EMAIL
    tty_read -p "$(echo -e "${CYAN}Admin username [admin]: ${NC}")" ADMIN_USER;   ADMIN_USER=${ADMIN_USER:-admin}
    tty_read -p "$(echo -e "${CYAN}Admin first name [Admin]: ${NC}")" ADMIN_FNAME; ADMIN_FNAME=${ADMIN_FNAME:-Admin}
    tty_read -p "$(echo -e "${CYAN}Admin last name [User]: ${NC}")" ADMIN_LNAME;  ADMIN_LNAME=${ADMIN_LNAME:-User}
    tty_read -s -p "$(echo -e "${CYAN}Admin password: ${NC}")" ADMIN_PASS; echo ""
    tty_read -p "$(echo -e "${CYAN}Timezone [Asia/Kolkata]: ${NC}")" TIMEZONE;    TIMEZONE=${TIMEZONE:-Asia/Kolkata}

    echo -e "\n${YELLOW}Starting installation...${NC}\n"

    # ── 1. Ports ─────────────────────────────────────
    print_header "OPENING PORTS"
    apt-get install -y ufw >/dev/null 2>&1 || true
    for port in 22 80 443 8080 2022; do
        ufw allow $port/tcp >/dev/null 2>&1 || true
    done
    echo "y" | ufw enable >/dev/null 2>&1 || true
    print_ok "Ports 22, 80, 443, 8080, 2022 opened"

    # ── 2. Packages ───────────────────────────────────
    print_header "INSTALLING PACKAGES"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y >/dev/null 2>&1
    apt-get install -y \
        curl wget tar unzip git gnupg2 lsb-release \
        mariadb-server nginx supervisor \
        software-properties-common apt-transport-https ca-certificates \
        redis-server >/dev/null 2>&1
    print_ok "Base packages installed"

    # PHP 8.3
    print_step "Adding PHP 8.3..."
    (curl -sSL https://packages.sury.org/php/README.txt | bash - >/dev/null 2>&1) || \
    (add-apt-repository -y ppa:ondrej/php >/dev/null 2>&1) || true
    apt-get update -y >/dev/null 2>&1
    apt-get install -y \
        php8.3 php8.3-cli php8.3-fpm php8.3-common \
        php8.3-mysql php8.3-mbstring php8.3-bcmath \
        php8.3-xml php8.3-curl php8.3-zip php8.3-intl php8.3-gd \
        >/dev/null 2>&1
    print_ok "PHP 8.3 installed"

    # Composer
    print_step "Installing Composer..."
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer >/dev/null 2>&1
    print_ok "Composer installed"

    # ── 3. Database ───────────────────────────────────
    print_header "SETTING UP DATABASE"
    systemctl enable --now mariadb >/dev/null 2>&1 || true
    mysql -u root << SQL
DROP DATABASE IF EXISTS \`${DB_NAME}\`;
DROP USER IF EXISTS '${DB_USER}'@'127.0.0.1';
CREATE DATABASE \`${DB_NAME}\`;
CREATE USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL
    print_ok "Database ready (clean slate)"

    # ── 4. Panel files ────────────────────────────────
    print_header "DOWNLOADING PANEL"
    rm -rf /var/www/pterodactyl
    mkdir -p /var/www/pterodactyl
    cd /var/www/pterodactyl
    curl -Lo panel.tar.gz "https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz" 2>/dev/null
    tar -xzf panel.tar.gz >/dev/null 2>&1
    chmod -R 755 storage/* bootstrap/cache/
    rm -f panel.tar.gz
    print_ok "Panel files extracted"

    # ── 5. Composer ───────────────────────────────────
    print_header "INSTALLING DEPENDENCIES"
    COMPOSER_ALLOW_SUPERUSER=1 composer install \
        --no-dev --optimize-autoloader --no-interaction \
        >/dev/null 2>&1
    print_ok "Composer dependencies installed"

    # ── 6. .env (direct write — no artisan prompts) ───
    print_header "CONFIGURING .ENV"
    cp .env.example .env
    php artisan key:generate --force --no-interaction >/dev/null 2>&1

    # Write all values directly — no interactive artisan commands
    sed -i "s|APP_URL=.*|APP_URL=${PANEL_URL}|"           .env
    sed -i "s|APP_TIMEZONE=.*|APP_TIMEZONE=${TIMEZONE}|"  .env
    sed -i "s|DB_HOST=.*|DB_HOST=127.0.0.1|"              .env
    sed -i "s|DB_PORT=.*|DB_PORT=3306|"                   .env
    sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|"     .env
    sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|"     .env
    sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|"     .env
    sed -i "s|CACHE_DRIVER=.*|CACHE_DRIVER=redis|"        .env
    sed -i "s|SESSION_DRIVER=.*|SESSION_DRIVER=database|" .env
    sed -i "s|QUEUE_CONNECTION=.*|QUEUE_CONNECTION=database|" .env
    sed -i "s|REDIS_HOST=.*|REDIS_HOST=127.0.0.1|"        .env

    # Store install info for uninstall
    cat > /etc/pterodactyl-jayanth.conf << CONF
FQDN=${FQDN}
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
USE_SSL=${USE_SSL}
CONF
    print_ok ".env configured (no interactive prompts)"

    # ── 7. Migrate ────────────────────────────────────
    print_header "RUNNING MIGRATIONS"
    systemctl enable --now redis-server >/dev/null 2>&1 || true
    php artisan migrate --seed --force --no-interaction >/dev/null 2>&1
    print_ok "Database migrated"

    php artisan p:user:make \
        --email="$ADMIN_EMAIL" \
        --username="$ADMIN_USER" \
        --name-first="$ADMIN_FNAME" \
        --name-last="$ADMIN_LNAME" \
        --password="$ADMIN_PASS" \
        --admin=1 \
        --no-interaction \
        >/dev/null 2>&1 || true
    print_ok "Admin user created"

    # ── 8. Permissions ────────────────────────────────
    chown -R www-data:www-data /var/www/pterodactyl/* >/dev/null 2>&1

    # ── 9. Cron ───────────────────────────────────────
    (crontab -l 2>/dev/null | grep -v "pterodactyl"; \
     echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -
    print_ok "Cron job added"

    # ── 10. Queue worker ──────────────────────────────
    print_header "QUEUE WORKER"
    cat > /etc/supervisor/conf.d/pterodactyl-worker.conf << 'EOF'
[program:pterodactyl-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/pterodactyl/artisan queue:work --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/www/pterodactyl/storage/logs/worker.log
stopwaitsecs=3600
EOF
    supervisorctl reread >/dev/null 2>&1 || true
    supervisorctl update >/dev/null 2>&1 || true
    print_ok "Queue worker configured"

    # ── 11. Nginx ─────────────────────────────────────
    print_header "CONFIGURING NGINX"
    rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
    cat > /etc/nginx/sites-available/pterodactyl.conf << NGINX
server {
    listen 80;
    server_name ${FQDN};
    root /var/www/pterodactyl/public;
    index index.php;
    charset utf-8;
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }
    access_log off;
    error_log /var/log/nginx/pterodactyl.app-error.log error;
    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_read_timeout 300;
    }
    location ~ /\.ht { deny all; }
}
NGINX
    ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/
    systemctl enable --now php8.3-fpm >/dev/null 2>&1 || true
    nginx -t >/dev/null 2>&1 && systemctl restart nginx >/dev/null 2>&1 || true
    print_ok "Nginx configured"

    # ── 12. SSL ───────────────────────────────────────
    if [[ "$USE_SSL" == "yes" ]]; then
        print_header "SSL (Let's Encrypt)"
        apt-get install -y certbot python3-certbot-nginx >/dev/null 2>&1
        certbot --nginx -d "$FQDN" \
            --non-interactive --agree-tos -m "$ADMIN_EMAIL" \
            --redirect >/dev/null 2>&1 || \
        certbot certonly --nginx -d "$FQDN" \
            --non-interactive --agree-tos -m "$ADMIN_EMAIL" >/dev/null 2>&1
        systemctl restart nginx >/dev/null 2>&1 || true
        print_ok "SSL certificate installed"
    fi

    # ── Done ──────────────────────────────────────────
    print_header "INSTALLATION COMPLETE"
    echo -e "${GREEN}🎉 Panel installed!${NC}"
    echo ""
    echo -e " ${CYAN}URL         :${NC} ${GREEN}${PANEL_URL}${NC}"
    echo -e " ${CYAN}Admin User  :${NC} ${GREEN}${ADMIN_USER}${NC}"
    echo -e " ${CYAN}Admin Email :${NC} ${GREEN}${ADMIN_EMAIL}${NC}"
    echo -e " ${CYAN}DB Password :${NC} ${GREEN}${DB_PASS}${NC} ${YELLOW}← Save this!${NC}"
    echo -e " ${CYAN}Ports Open  :${NC} ${GREEN}22, 80, 443, 8080, 2022${NC}"
    echo ""
}

# ════════════════════════════════════════════════════
# UNINSTALL — clean for reinstall
# ════════════════════════════════════════════════════
uninstall_panel() {
    clear
    echo -e "${RED}⚠  UNINSTALL — everything will be removed cleanly${NC}"
    echo ""

    # Auto-read install info if exists
    FQDN=""; DB_NAME="panel"; DB_USER="pterodactyl"; USE_SSL="no"
    if [ -f /etc/pterodactyl-jayanth.conf ]; then
        source /etc/pterodactyl-jayanth.conf
        echo -e " ${CYAN}Detected:${NC} FQDN=${GREEN}$FQDN${NC} DB=${GREEN}$DB_NAME${NC}"
    elif [ -f /var/www/pterodactyl/.env ]; then
        DB_NAME=$(grep "^DB_DATABASE=" /var/www/pterodactyl/.env | cut -d= -f2)
        DB_USER=$(grep "^DB_USERNAME=" /var/www/pterodactyl/.env | cut -d= -f2)
        APP_URL=$(grep "^APP_URL=" /var/www/pterodactyl/.env | cut -d= -f2)
        FQDN=$(echo "$APP_URL" | sed 's|https\?://||' | sed 's|/.*||')
        echo -e " ${CYAN}Detected from .env:${NC} FQDN=${GREEN}$FQDN${NC} DB=${GREEN}$DB_NAME${NC}"
    fi

    echo ""
    tty_read -p "$(echo -e "${YELLOW}Type 'yes' to confirm full uninstall: ${NC}")" CONFIRM
    [[ "$CONFIRM" != "yes" ]] && { echo -e "${GREEN}Cancelled.${NC}"; sleep 1; return; }

    print_header "UNINSTALLING"

    # Stop services
    systemctl stop pterodactyl 2>/dev/null || true
    supervisorctl stop pterodactyl-worker:* 2>/dev/null || true

    # Remove panel files
    rm -rf /var/www/pterodactyl
    print_ok "Panel files removed"

    # Remove nginx config
    rm -f /etc/nginx/sites-enabled/pterodactyl.conf
    rm -f /etc/nginx/sites-available/pterodactyl.conf
    nginx -t >/dev/null 2>&1 && systemctl reload nginx >/dev/null 2>&1 || true
    print_ok "Nginx config removed"

    # Remove supervisor config
    rm -f /etc/supervisor/conf.d/pterodactyl-worker.conf
    supervisorctl reread >/dev/null 2>&1 || true
    supervisorctl update >/dev/null 2>&1 || true
    print_ok "Queue worker removed"

    # Remove cron
    crontab -l 2>/dev/null | grep -v "pterodactyl" | crontab - 2>/dev/null || true
    print_ok "Cron job removed"

    # Drop DB (IF EXISTS — no error on reinstall)
    mysql -u root << SQL 2>/dev/null || true
DROP DATABASE IF EXISTS \`${DB_NAME}\`;
DROP USER IF EXISTS '${DB_USER}'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL
    print_ok "Database and user dropped (clean)"

    # Remove SSL certs
    if [ -n "$FQDN" ]; then
        certbot delete --cert-name "$FQDN" --non-interactive >/dev/null 2>&1 || true
        rm -rf "/etc/letsencrypt/live/${FQDN}" 2>/dev/null || true
        rm -rf "/etc/letsencrypt/renewal/${FQDN}.conf" 2>/dev/null || true
        print_ok "SSL certificates removed"
    fi

    # Remove install config
    rm -f /etc/pterodactyl-jayanth.conf

    print_header "UNINSTALL COMPLETE"
    echo -e "${GREEN}✓ All panel data removed — ready for fresh reinstall!${NC}"
    echo ""
}

# ════════════════════════════════════════════════════
# MAIN MENU
# ════════════════════════════════════════════════════
while true; do
    clear
    echo -e "${VIOLET}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${VIOLET}║${NC}      ${P}★ JAYANTH HUB${NC} ${DG}::${NC} ${CYAN}PTERODACTYL PANEL MANAGER${NC}      ${VIOLET}║${NC}"
    echo -e "${VIOLET}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e " ${YELLOW}SELECT AN ACTION:${NC}"
    echo -e " ${DG}──────────────────────────────────────────────────────────${NC}"
    echo -e " ${P}[1]${NC} ${GREEN}Install Pterodactyl Panel${NC}   ${DG}:: IP or Domain + SSL${NC}"
    echo -e " ${P}[2]${NC} ${RED}Uninstall Pterodactyl Panel${NC} ${DG}:: Clean remove for reinstall${NC}"
    echo -e " ${DG}──────────────────────────────────────────────────────────${NC}"
    echo -e " ${P}[0]${NC} ${DG}Back to JAYANTH HUB${NC}"
    echo ""
    echo -ne " ${CYAN}➜${NC} Enter Option: "
    tty_read opt

    case $opt in
        1) install_panel;   pause_return ;;
        2) uninstall_panel; pause_return ;;
        0) exit 0 ;;
        *) echo -e " ${RED}✘ Invalid.${NC}"; sleep 0.8 ;;
    esac
done
