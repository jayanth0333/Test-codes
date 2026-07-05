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

tty_read() { read "$@" < /dev/tty; }

header() {
    clear
    echo -e "${VIOLET}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${VIOLET}║${NC}      ${P}★ JAYANTH HUB${NC} ${DG}::${NC} ${C}PTERODACTYL PANEL MANAGER${NC}      ${VIOLET}║${NC}"
    echo -e "${VIOLET}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

while true; do
    header
    echo -e " ${Y}SELECT AN ACTION:${NC}"
    echo -e " ${DG}──────────────────────────────────────────────────────────${NC}"
    echo -e " ${P}[1]${NC} ${W}Install Pterodactyl Panel${NC}   ${DG}:: Official Installer${NC}"
    echo -e " ${P}[2]${NC} ${R}Uninstall Pterodactyl Panel${NC} ${DG}:: Remove Panel Only${NC}"
    echo -e " ${DG}──────────────────────────────────────────────────────────${NC}"
    echo -e " ${P}[0]${NC} ${DG}Back to JAYANTH HUB${NC}"
    echo ""
    echo -ne " ${C}➜${NC} ${W}Enter Option:${NC} "
    tty_read opt

    case $opt in
        1)
            echo -e "\n ${G}▶ Downloading Official Pterodactyl Panel Installer...${NC}\n"
            sleep 0.5
            # Download to temp file so stdin stays connected to terminal
            curl -sSL \
                "https://raw.githubusercontent.com/pterodactyl-installer/pterodactyl-installer/master/install.sh" \
                -o /tmp/ptero-install.sh
            # Set source so it runs panel UI directly
            export GITHUB_SOURCE="master"
            export GITHUB_BASE_URL="https://raw.githubusercontent.com/pterodactyl-installer/pterodactyl-installer"
            # Run directly (not via process substitution — stdin works properly)
            bash /tmp/ptero-install.sh
            rm -f /tmp/ptero-install.sh
            echo ""
            tty_read -n 1 -s -r -p "  Press any key to return..."
            echo ""
            ;;
        2)
            echo -e "\n ${R}▶ Downloading Official Pterodactyl Uninstaller...${NC}\n"
            sleep 0.5
            export GITHUB_SOURCE="master"
            export GITHUB_BASE_URL="https://raw.githubusercontent.com/pterodactyl-installer/pterodactyl-installer"
            curl -sSL \
                "https://raw.githubusercontent.com/pterodactyl-installer/pterodactyl-installer/master/lib/lib.sh" \
                -o /tmp/ptero-lib.sh
            # shellcheck source=/dev/null
            source /tmp/ptero-lib.sh
            # Download uninstall UI to temp file and run directly
            curl -sSL \
                "https://raw.githubusercontent.com/pterodactyl-installer/pterodactyl-installer/master/ui/uninstall.sh" \
                -o /tmp/ptero-uninstall.sh
            bash /tmp/ptero-uninstall.sh
            rm -f /tmp/ptero-lib.sh /tmp/ptero-uninstall.sh
            echo ""
            tty_read -n 1 -s -r -p "  Press any key to return..."
            echo ""
            ;;
        0) exit 0 ;;
        *) echo -e " ${R}✘ Invalid option.${NC}"; sleep 0.8 ;;
    esac
done
