#!/usr/bin/env bash

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
P='\033[1;38;5;201m'; VIOLET='\033[1;38;5;135m'; DG='\033[0;38;5;244m'
NC='\033[0m'

tty_read() { read "$@" < /dev/tty; }
print_header() {
    echo -e "\n${MAGENTA}╔══════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}${CYAN}   $1${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════╝${NC}"
}
print_step()    { echo -e "${YELLOW}➤ $1${NC}"; }
print_ok()      { echo -e "${GREEN}✓ $1${NC}"; }
print_err()     { echo -e "${RED}✗ $1${NC}"; }
pause_return()  { echo ""; tty_read -n 1 -s -r -p "  Press any key to return..."; echo ""; exit 0; }

install_panel() {
    clear
    echo -e "${VIOLET}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${VIOLET}║${NC}        ${P}★ JAYANTH HUB :: PANEL INSTALLER${NC}            ${VIOLET}║${NC}"
    echo -e "${VIOLET}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ "$EUID" -ne 0 ]; then print_err "Run as root!"; pause_return; fi

    # ── Collect info ─────────────────────────────────────
    print_header "CONFIGURATION"

    tty_read -p "$(echo -e "${CYAN}Use IP or Domain? (ip/domain): ${NC}")" CONN_TYPE
    if [[ "$CONN_TYPE" == "domain" ]]; then
        tty_read -p "$(echo -e "${CYAN}Enter your domain (e.g. panel.example.com): ${NC}")" FQDN
        USE_SSL="yes"
    else
        FQDN=$(curl -s --max-time 5 ifconfig.me || hostname -I | awk '{print $1}')
        echo -e "${GREEN}Detected IP: $FQDN${NC}"
        USE_SSL="no"
    fi

    tty_read -p "$(echo -e "${CYAN}Database name [panel]: ${NC}")" DB_NAME
    DB_NAME=${DB_NAME:-panel}

    tty_read -p "$(echo -e "${CYAN}Database username [pterodactyl]: ${NC}")" DB_USER
    DB_USER=${DB_USER:-pterodactyl}

    DB_PASS=$(tr -dc 'A-Za-z0-9@#$' < /dev/urandom | head -c 20)
    echo -e "${YELLOW}Auto-generated DB password: ${GREEN}$DB_PASS${NC}"

    tty_read -p "$(echo -e "${CYAN}Admin email: ${NC}")" ADMIN_EMAIL
    tty_read -p "$(echo -e "${CYAN}Admin username [admin]: ${NC}")" ADMIN_USER
    ADMIN_USER=${ADMIN_USER:-admin}
    tty_read -p "$(echo -e "${CYAN}Admin first name [Admin]: ${NC}")" ADMIN_FNAME
    ADMIN_FNAME=${ADMIN_FNAME:-Admin}
    tty_read -p "$(echo -e "${CYAN}Admin last name [User]: ${NC}")" ADMIN_LNAME
    ADMIN_LNAME=${ADMIN_LNAME:-User}
    tty_read -s -p "$(echo -e "${CYAN}Admin password: ${NC}")" ADMIN_PASS
    echo ""
    tty_read -p "$(echo -e "${CYAN}Timezone [Asia/Kolkata]: ${NC}")" TIMEZONE
    TIMEZONE=${TIMEZONE:-Asia/Kolkata}

    echo -e "\n${YELLOW}Starting installation...${NC}\n"

    # ── 1. Ports ─────────────────────────────────────────
    print_header "OPENING PORTS"
    apt-get install -y ufw >/dev/null 2>&1 || true
    ufw allow 22/tcp >/dev/null 2>&1 || true
    ufw allow 80/tcp >/dev/null 2>&1 || true
    ufw allow 443/tcp >/dev/null 2>&1 || true
    ufw allow 8080/tcp >/dev/null 2>&1 || true
    ufw allow 2022/tcp >/dev/null 2>&1 || true
    echo "y" | ufw enable >/dev/null 2>&1 || true
    print_ok "Ports 22, 80, 443, 8080, 2022 opened"

    # ── 2. Dependencies ───────────────────────────────────
    print_header "INSTALLING DEPENDENCIES"
    apt-get update -y >/dev/null 2>&1
    apt-get install -y \
        curl wget tar unzip git gnupg2 lsb-release \
        mariadb-server nginx \
        software-properties-common apt-transport-https ca-certificates \
        >/dev/null 2>&1
    print_ok "Base packages installed"

    # PHP 8.3
    print_step "Adding PHP 8.3 repository..."
    curl -sSL https://packages.sury.org/php/README.txt | bash - >/dev/null 2>&1 || \
    add-apt-repository -y ppa:ondrej/php >/dev/null 2>&1 || true
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

    # ── 3. Database ───────────────────────────────────────
    print_header "SETTING UP DATABASE"
    systemctl enable --now mariadb >/dev/null 2>&1 || true
    mysql -u root << SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL
    print_ok "Database '$DB_NAME' and user '$DB_USER' created"

    # ── 4. Panel files ────────────────────────────────────
    print_header "DOWNLOADING PANEL"
    mkdir -p /var/www/pterodactyl
    cd /var/www/pterodactyl || exit 1
    print_step "Downloading latest Pterodactyl panel..."
    curl -Lo panel.tar.gz "https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz"
    tar -xzvf panel.tar.gz >/dev/null 2>&1
    chmod -R 755 storage/* bootstrap/cache/
    rm -f panel.tar.gz
    print_ok "Panel files extracted"

    # ── 5. Composer & .env ────────────────────────────────
    print_header "CONFIGURING PANEL"
    cp .env.example .env
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --no-interaction >/dev/null 2>&1
    print_ok "Composer dependencies installed"

    php artisan key:generate --force >/dev/null 2>&1

    # Set .env values
    sed -i "s|APP_URL=.*|APP_URL=http://${FQDN}|" .env
    sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|" .env
    sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|" .env
    sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|" .env

    php artisan p:environment:setup \
        --author="$ADMIN_EMAIL" \
        --url="http://${FQDN}" \
        --timezone="$TIMEZONE" \
        --cache=redis \
        --session=database \
        --queue=database \
        --redis-host=127.0.0.1 \
        --redis-pass="null" \
        --redis-port=6379 \
        --disable-settings-ui \
        >/dev/null 2>&1 || true

    php artisan p:environment:database \
        --host=127.0.0.1 \
        --port=3306 \
        --database="$DB_NAME" \
        --username="$DB_USER" \
        --password="$DB_PASS" \
        >/dev/null 2>&1 || true

    print_ok ".env configured"

    # ── 6. Migrations & admin ─────────────────────────────
    print_header "RUNNING MIGRATIONS"
    php artisan migrate --seed --force >/dev/null 2>&1
    print_ok "Database migrated"

    php artisan p:user:make \
        --email="$ADMIN_EMAIL" \
        --username="$ADMIN_USER" \
        --name-first="$ADMIN_FNAME" \
        --name-last="$ADMIN_LNAME" \
        --password="$ADMIN_PASS" \
        --admin=1 \
        >/dev/null 2>&1 || true
    print_ok "Admin user '$ADMIN_USER' created"

    # ── 7. Permissions ────────────────────────────────────
    chown -R www-data:www-data /var/www/pterodactyl/* >/dev/null 2>&1

    # ── 8. Cron ───────────────────────────────────────────
    (crontab -l 2>/dev/null; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -
    print_ok "Cron job added"

    # ── 9. Queue worker ───────────────────────────────────
    print_header "CONFIGURING QUEUE WORKER"
    apt-get install -y supervisor >/dev/null 2>&1 || true
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

    # ── 10. Nginx ─────────────────────────────────────────
    print_header "CONFIGURING NGINX"
    rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
    cat > /etc/nginx/sites-available/pterodactyl.conf << NGINX
server {
    listen 80;
    server_name ${FQDN};
    root /var/www/pterodactyl/public;
    index index.html index.htm index.php;
    charset utf-8;
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
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
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_read_timeout 300;
    }
    location ~ /\.ht { deny all; }
}
NGINX
    ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
    systemctl restart nginx >/dev/null 2>&1 || true
    print_ok "Nginx configured"

    # ── 11. SSL ───────────────────────────────────────────
    if [[ "$USE_SSL" == "yes" ]]; then
        print_header "SETTING UP SSL (Let's Encrypt)"
        apt-get install -y certbot python3-certbot-nginx >/dev/null 2>&1
        certbot --nginx -d "$FQDN" --non-interactive --agree-tos -m "$ADMIN_EMAIL" >/dev/null 2>&1 || \
        certbot certonly --nginx -d "$FQDN" --non-interactive --agree-tos -m "$ADMIN_EMAIL"
        systemctl restart nginx >/dev/null 2>&1 || true
        PANEL_URL="https://$FQDN"
        print_ok "SSL certificate installed"
    else
        PANEL_URL="http://$FQDN"
        print_ok "No SSL (IP mode) — skipped"
    fi

    # ── Done ──────────────────────────────────────────────
    print_header "INSTALLATION COMPLETE"
    echo -e "${GREEN}🎉 Pterodactyl Panel installed successfully!${NC}"
    echo ""
    echo -e " ${CYAN}Panel URL   :${NC} ${GREEN}$PANEL_URL${NC}"
    echo -e " ${CYAN}Admin Email :${NC} ${GREEN}$ADMIN_EMAIL${NC}"
    echo -e " ${CYAN}Admin User  :${NC} ${GREEN}$ADMIN_USER${NC}"
    echo -e " ${CYAN}DB Password :${NC} ${GREEN}$DB_PASS${NC} ${YELLOW}(save this!)${NC}"
    echo -e " ${CYAN}Open Ports  :${NC} ${GREEN}22, 80, 443, 8080, 2022${NC}"
    echo ""
}

uninstall_panel() {
    clear
    echo -e "${RED}⚠  WARNING: This will remove Pterodactyl Panel completely!${NC}"
    echo ""
    tty_read -p "$(echo -e "${YELLOW}Type 'yes' to confirm uninstall: ${NC}")" CONFIRM
    if [[ "$CONFIRM" != "yes" ]]; then
        echo -e "${GREEN}Cancelled.${NC}"; sleep 1; return
    fi

    print_header "UNINSTALLING PANEL"
    systemctl stop nginx php8.3-fpm mariadb >/dev/null 2>&1 || true
    rm -rf /var/www/pterodactyl
    rm -f /etc/nginx/sites-enabled/pterodactyl.conf
    rm -f /etc/nginx/sites-available/pterodactyl.conf
    rm -f /etc/supervisor/conf.d/pterodactyl-worker.conf
    mysql -u root -e "DROP DATABASE IF EXISTS panel; DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';" 2>/dev/null || true
    crontab -l 2>/dev/null | grep -v "pterodactyl" | crontab - 2>/dev/null || true
    systemctl restart nginx >/dev/null 2>&1 || true
    print_ok "Panel removed"
}

# ── Main menu ─────────────────────────────────────
tty_read() { read "$@" < /dev/tty; }

while true; do
    clear
    echo -e "${VIOLET}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${VIOLET}║${NC}      ${P}★ JAYANTH HUB${NC} ${DG}::${NC} ${CYAN}PTERODACTYL PANEL MANAGER${NC}      ${VIOLET}║${NC}"
    echo -e "${VIOLET}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e " ${YELLOW}SELECT AN ACTION:${NC}"
    echo -e " ${DG}──────────────────────────────────────────────────────────${NC}"
    echo -e " ${P}[1]${NC} ${GREEN}Install Pterodactyl Panel${NC}   ${DG}:: IP or Domain + SSL${NC}"
    echo -e " ${P}[2]${NC} ${RED}Uninstall Pterodactyl Panel${NC} ${DG}:: Remove completely${NC}"
    echo -e " ${DG}──────────────────────────────────────────────────────────${NC}"
    echo -e " ${P}[0]${NC} ${DG}Back to JAYANTH HUB${NC}"
    echo ""
    echo -ne " ${CYAN}➜${NC} Enter Option: "
    tty_read opt

    case $opt in
        1) install_panel; pause_return ;;
        2) uninstall_panel; pause_return ;;
        0) exit 0 ;;
        *) echo -e " ${RED}✘ Invalid option.${NC}"; sleep 0.8 ;;
    esac
done
