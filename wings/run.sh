#!/usr/bin/env bash

tty_read() { read "$@" < /dev/tty; }

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
WHITE='\033[1;37m'; DIM='\033[2m'; NC='\033[0m'

BASE="https://raw.githubusercontent.com/jayanth0333/Test-codes/main"

show_menu() {
    clear
    HOST=$(hostname)
    WAN=$(curl -s --max-time 3 ifconfig.me 2>/dev/null || echo "Unknown")
    LAN=$(hostname -I 2>/dev/null | awk '{print $1}')
    RAM=$(free -h | awk '/Mem:/{print $3"/"$2}')
    OS=$(lsb_release -d 2>/dev/null | cut -f2 || uname -o)

    echo -e " ${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e " ${BLUE}║${NC}   ${CYAN}⚡  JAYANTH HUB v1.0 :: WINGS MANAGER${NC}              ${BLUE}║${NC}"
    echo -e " ${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"
    printf " ${BLUE}║${NC}  %-6s: %-20s %-4s: %-18s${BLUE}║${NC}\n" "OS" "$OS" "WAN" "$WAN"
    printf " ${BLUE}║${NC}  %-6s: %-20s %-4s: %-18s${BLUE}║${NC}\n" "RAM" "$RAM" "LAN" "$LAN"
    echo -e " ${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${WHITE}AVAILABLE MODULES:${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────${NC}"
    echo -e "  ${CYAN}[1]${NC} SSL Configuration    ${DIM}:: (Certbot/Nginx)${NC}"
    echo -e "  ${CYAN}[2]${NC} Install Wings        ${DIM}:: (JAYANTH Script)${NC}"
    echo -e "  ${CYAN}[3]${NC} Manager              ${DIM}:: (Wings Manager)${NC}"
    echo -e "  ${CYAN}[4]${NC} Database Manager     ${DIM}:: (MySQL/MariaDB)${NC}"
    echo -e "  ${CYAN}[5]${NC} Uninstall            ${DIM}:: (Remove Wings)${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────${NC}"
    echo -e "  ${RED}[0]${NC} Exit System"
    echo ""
    echo -ne "  ${WHITE}Select Module: ${NC}"
}

# ── 1. SSL ────────────────────────────────────────
ssl_config() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     SSL CONFIGURATION (Certbot)      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
    echo ""
    tty_read -p "  Enter domain (e.g. node.example.com): " DOMAIN
    tty_read -p "  Enter email: " EMAIL
    echo ""
    apt-get install -y certbot python3-certbot-nginx >/dev/null 2>&1
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect
    echo -e "\n${GREEN}✓ SSL configured for $DOMAIN${NC}"
    echo ""; tty_read -n 1 -s -r -p "  Press any key..."; echo ""
}

# ── 2. Install Wings ──────────────────────────────
install_wings() {
    bash <(curl -fsSL "$BASE/wings/install.sh")
}

# ── 3. Manager ────────────────────────────────────
wings_manager() {
    while true; do
        clear
        STATUS=$(systemctl is-active wings 2>/dev/null || echo "inactive")
        [ "$STATUS" = "active" ] && SC="${GREEN}" || SC="${RED}"
        echo -e "${MAGENTA}╔══════════════════════════════════════╗${NC}"
        echo -e "${MAGENTA}║         WINGS MANAGER                ║${NC}"
        echo -e "${MAGENTA}╚══════════════════════════════════════╝${NC}"
        echo -e "  Status: ${SC}${STATUS}${NC}"
        echo ""
        echo -e "  ${CYAN}[1]${NC} Start Wings"
        echo -e "  ${CYAN}[2]${NC} Stop Wings"
        echo -e "  ${CYAN}[3]${NC} Restart Wings"
        echo -e "  ${CYAN}[4]${NC} View Logs (last 50 lines)"
        echo -e "  ${CYAN}[5]${NC} Enable autostart"
        echo -e "  ${CYAN}[6]${NC} Disable autostart"
        echo -e "  ${RED}[0]${NC} Back"
        echo ""
        echo -ne "  Select: "
        tty_read m
        case $m in
            1) systemctl start wings && echo -e "${GREEN}✓ Started${NC}" || echo -e "${RED}✗ Failed${NC}"; sleep 1 ;;
            2) systemctl stop wings && echo -e "${GREEN}✓ Stopped${NC}"; sleep 1 ;;
            3) systemctl restart wings && echo -e "${GREEN}✓ Restarted${NC}"; sleep 1 ;;
            4) journalctl -u wings -n 50 --no-pager; echo ""; tty_read -n 1 -s -r -p "  Press any key..."; echo "" ;;
            5) systemctl enable wings && echo -e "${GREEN}✓ Autostart enabled${NC}"; sleep 1 ;;
            6) systemctl disable wings && echo -e "${YELLOW}✓ Autostart disabled${NC}"; sleep 1 ;;
            0) break ;;
        esac
    done
}

# ── 4. Database Manager ───────────────────────────
db_manager() {
    while true; do
        clear
        echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║      WINGS DATABASE MANAGER          ║${NC}"
        echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${CYAN}[1]${NC} Create Wings Database + User"
        echo -e "  ${CYAN}[2]${NC} List All Databases"
        echo -e "  ${CYAN}[3]${NC} Delete Database"
        echo -e "  ${CYAN}[4]${NC} Reset Root Password"
        echo -e "  ${CYAN}[5]${NC} MySQL Status"
        echo -e "  ${RED}[0]${NC} Back"
        echo ""
        echo -ne "  Select: "
        tty_read d
        case $d in
            1)
                tty_read -p "  DB Name [wingsdb]: " WDBNAME; WDBNAME=${WDBNAME:-wingsdb}
                tty_read -p "  DB User [wingsuser]: " WDBUSER; WDBUSER=${WDBUSER:-wingsuser}
                WDBPASS=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
                mysql -u root << SQL 2>/dev/null
CREATE DATABASE IF NOT EXISTS \`${WDBNAME}\`;
DROP USER IF EXISTS '${WDBUSER}'@'%';
CREATE USER '${WDBUSER}'@'%' IDENTIFIED BY '${WDBPASS}';
GRANT ALL PRIVILEGES ON \`${WDBNAME}\`.* TO '${WDBUSER}'@'%';
FLUSH PRIVILEGES;
SQL
                echo -e "\n${GREEN}✓ Created!${NC}"
                echo -e "  DB:   ${CYAN}$WDBNAME${NC}"
                echo -e "  User: ${CYAN}$WDBUSER${NC}"
                echo -e "  Pass: ${YELLOW}$WDBPASS${NC}"
                echo ""; tty_read -n 1 -s -r -p "  Press any key..."; echo ""
                ;;
            2)
                mysql -u root -e "SHOW DATABASES;" 2>/dev/null
                echo ""; tty_read -n 1 -s -r -p "  Press any key..."; echo ""
                ;;
            3)
                tty_read -p "  DB Name to delete: " DELDB
                mysql -u root -e "DROP DATABASE IF EXISTS \`${DELDB}\`;" 2>/dev/null
                echo -e "${GREEN}✓ Deleted $DELDB${NC}"; sleep 1
                ;;
            4)
                tty_read -s -p "  New root password: " NEWROOTPASS; echo ""
                mysql -u root << SQL 2>/dev/null
ALTER USER 'root'@'localhost' IDENTIFIED BY '${NEWROOTPASS}';
FLUSH PRIVILEGES;
SQL
                echo -e "${GREEN}✓ Root password updated${NC}"; sleep 1
                ;;
            5)
                systemctl status mariadb --no-pager | head -20
                echo ""; tty_read -n 1 -s -r -p "  Press any key..."; echo ""
                ;;
            0) break ;;
        esac
    done
}

# ── 5. Uninstall Wings ────────────────────────────
uninstall_wings() {
    clear
    echo -e "${RED}⚠  This will remove Wings completely${NC}"
    echo ""
    tty_read -p "  Type 'yes' to confirm: " CONFIRM
    [[ "$CONFIRM" != "yes" ]] && { echo -e "${GREEN}Cancelled.${NC}"; sleep 1; return; }

    systemctl stop wings 2>/dev/null || true
    systemctl disable wings 2>/dev/null || true
    rm -f /usr/local/bin/wings
    rm -f /etc/systemd/system/wings.service
    rm -rf /etc/pterodactyl
    rm -rf /var/lib/pterodactyl
    systemctl daemon-reload >/dev/null 2>&1 || true
    echo -e "\n${GREEN}✓ Wings removed${NC}"
    echo ""; tty_read -n 1 -s -r -p "  Press any key..."; echo ""
}

# ── Main loop ─────────────────────────────────────
while true; do
    show_menu
    tty_read opt
    case $opt in
        1) ssl_config ;;
        2) install_wings ;;
        3) wings_manager ;;
        4) db_manager ;;
        5) uninstall_wings ;;
        0) exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 0.8 ;;
    esac
done
