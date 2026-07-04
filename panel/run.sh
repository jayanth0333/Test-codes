#!/usr/bin/env bash
# ============================================================
# JAYANTH HUB — PTERODACTYL PANEL MANAGER
# ============================================================
set -e

P='\033[1;38;5;201m'
VIOLET='\033[1;38;5;135m'
G='\033[1;38;5;82m'
R='\033[1;38;5;196m'
Y='\033[1;38;5;220m'
C='\033[1;38;5;51m'
W='\033[1;38;5;255m'
DG='\033[0;38;5;244m'
NC='\033[0m'

header() {
    clear
    echo -e "${VIOLET}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${VIOLET}║${NC}      ${P}★ JAYANTH HUB${NC} ${DG}::${NC} ${C}PTERODACTYL PANEL MANAGER${NC}      ${VIOLET}║${NC}"
    echo -e "${VIOLET}╚══════════════════════════════════════════════════════════╝${NC}"
    echo -e ""
}

while true; do
    header
    echo -e " ${Y}SELECT AN ACTION:${NC}"
    echo -e " ${DG}──────────────────────────────────────────────────────────${NC}"
    echo -e " ${P}[1]${NC} ${W}Install Pterodactyl Panel${NC}   ${DG}:: Official Installer${NC}"
    echo -e " ${P}[2]${NC} ${R}Uninstall Pterodactyl Panel${NC} ${DG}:: Remove Panel Only${NC}"
    echo -e " ${DG}──────────────────────────────────────────────────────────${NC}"
    echo -e " ${P}[0]${NC} ${DG}Back to JAYANTH HUB${NC}"
    echo -e ""
    echo -ne " ${C}➜${NC} ${W}Enter Option:${NC} "
    read -r opt

    case $opt in
        1)
            echo -e "\n ${G}▶ Loading Official Pterodactyl Panel Installer...${NC}\n"
            sleep 0.8
            export GITHUB_SOURCE="v1.3.0"
            export GITHUB_BASE_URL="https://raw.githubusercontent.com/pterodactyl-installer/pterodactyl-installer"
            [ -f /tmp/lib.sh ] && rm -f /tmp/lib.sh
            curl -sSL -o /tmp/lib.sh "$GITHUB_BASE_URL/master/lib/lib.sh"
            source /tmp/lib.sh
            update_lib_source
            run_ui "panel"
            rm -f /tmp/lib.sh
            echo -e "\n ${G}✔ Done. Press Enter to return.${NC}"; read -r
            ;;
        2)
            echo -e "\n ${R}▶ Loading Official Pterodactyl Uninstaller...${NC}\n"
            sleep 0.8
            export GITHUB_SOURCE="v1.3.0"
            export GITHUB_BASE_URL="https://raw.githubusercontent.com/pterodactyl-installer/pterodactyl-installer"
            [ -f /tmp/lib.sh ] && rm -f /tmp/lib.sh
            curl -sSL -o /tmp/lib.sh "$GITHUB_BASE_URL/master/lib/lib.sh"
            source /tmp/lib.sh
            update_lib_source
            run_ui "uninstall"
            rm -f /tmp/lib.sh
            echo -e "\n ${G}✔ Done. Press Enter to return.${NC}"; read -r
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e " ${R}✘ Invalid option.${NC}"; sleep 0.8
            ;;
    esac
done

