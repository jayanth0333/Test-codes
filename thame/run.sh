#!/usr/bin/env bash

P='\033[1;38;5;201m'
VIOLET='\033[1;38;5;135m'
G='\033[1;38;5;82m'
R='\033[1;38;5;196m'
Y='\033[1;38;5;220m'
C='\033[1;38;5;51m'
W='\033[1;38;5;255m'
DG='\033[0;38;5;244m'
NC='\033[0m'

BASE="https://raw.githubusercontent.com/jayanth0333/Test-codes/main"

while true; do
    clear
    echo -e "${VIOLET}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${VIOLET}║${NC}         ${P}★ JAYANTH HUB${NC} ${DG}::${NC} ${C}THEMES${NC}                   ${VIOLET}║${NC}"
    echo -e "${VIOLET}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e " ${Y}SELECT THEME TYPE:${NC}"
    echo -e " ${DG}────────────────────────────────────────────────────────────${NC}"
    echo -e " ${P}[1]${NC} ${W}Blueprint Themes${NC}  ${DG}:: Select & Install Blueprint UI Themes${NC}"
    echo -e " ${P}[2]${NC} ${W}Hyper Theme${NC}       ${DG}:: DGEN HyperV1 Theme Installer${NC}"
    echo -e " ${DG}────────────────────────────────────────────────────────────${NC}"
    echo -e " ${R}[0]${NC} ${DG}Back${NC}"
    echo -e " ${DG}────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -ne " ${C}➜${NC} ${W}Enter Option (0-2):${NC} "
    read -r opt

    case $opt in
        1) bash <(curl -fsSL "$BASE/thame/thames.sh") ;;
        2)
            clear
            echo -e "${VIOLET}╔══════════════════════════════════════════════════════════╗${NC}"
            echo -e "${VIOLET}║${NC}              ${P}★ HYPER THEME INSTALLER${NC}                ${VIOLET}║${NC}"
            echo -e "${VIOLET}╚══════════════════════════════════════════════════════════╝${NC}"
            echo ""
            echo -e " ${Y}⚠  This is a commercial theme by DGEN.${NC}"
            echo -e " ${DG}   Requires a valid HyperV1 license to complete install.${NC}"
            echo -e " ${DG}   Binary is downloaded directly from DGEN servers.${NC}"
            echo ""
            echo -ne " ${C}➜${NC} ${W}Proceed? (y/n):${NC} "
            read -r yn
            if [[ "$yn" == "y" || "$yn" == "Y" ]]; then
                echo -e "\n ${Y}[1/3] Navigating to Pterodactyl directory...${NC}"
                cd /var/www/pterodactyl 2>/dev/null || {
                    echo -e " ${R}✘ /var/www/pterodactyl not found. Install panel first!${NC}"
                    sleep 2; continue
                }
                echo -e " ${Y}[2/3] Downloading Hyper utility...${NC}"
                wget https://hyper-r2.dgenx.net/hyperv1/hyper-utility
                chmod +x hyper-utility
                echo -e " ${Y}[3/3] Running Hyper installer...${NC}"
                ./hyper-utility
                echo ""
                echo -e " ${Y}Applying migrations...${NC}"
                chmod 644 /var/www/pterodactyl/database/migrations/*.php
                cd /var/www/pterodactyl
                php artisan migrate --step --force
                echo ""
                echo -e " ${G}✔ Done! Press any key to return.${NC}"
                read -n 1 -s -r
            fi
            ;;
        0) exit 0 ;;
        *) echo -e " ${R}✘ Invalid option.${NC}"; sleep 0.8 ;;
    esac
done
