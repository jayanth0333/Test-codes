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

header() {
    clear
    echo -e "${VIOLET}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${VIOLET}║${NC}    ${P}★ JAYANTH HUB${NC} ${DG}::${NC} ${C}BLUEPRINT & EXTENSIONS${NC}          ${VIOLET}║${NC}"
    echo -e "${VIOLET}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

install_blueprint() {
    clear
    echo -e "${VIOLET}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${VIOLET}║${NC}         ${P}★ INSTALL BLUEPRINT FRAMEWORK${NC}               ${VIOLET}║${NC}"
    echo -e "${VIOLET}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e " ${Y}What this will install:${NC}"
    echo -e " ${DG}────────────────────────────────────────────────────────────${NC}"
    echo -e " ${P}●${NC} ${W}Blueprint Framework${NC} ${DG}(latest release)${NC}"
    echo -e " ${P}●${NC} ${W}Node.js v22${NC} ${DG}(official NodeSource repo)${NC}"
    echo -e " ${P}●${NC} ${W}Yarn${NC} ${DG}(package manager)${NC}"
    echo -e " ${P}●${NC} ${W}Dependencies${NC} ${DG}(curl, wget, unzip, git, gnupg, zip)${NC}"
    echo -e " ${DG}────────────────────────────────────────────────────────────${NC}"
    echo -e " ${Y}Directory:${NC} ${W}/var/www/pterodactyl${NC}"
    echo ""
    echo -ne " ${C}➜${NC} ${W}Proceed with installation? (y/n):${NC} "
    read -r confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "\n ${R}Cancelled.${NC}"; sleep 1; return
    fi

    export PTERODACTYL_DIRECTORY=/var/www/pterodactyl

    echo -e "\n ${Y}[1/6] Installing base dependencies...${NC}"
    apt install -y curl wget unzip

    echo -e "\n ${Y}[2/6] Downloading Blueprint latest release...${NC}"
    cd "$PTERODACTYL_DIRECTORY" || { echo -e " ${R}✘ /var/www/pterodactyl not found. Install Pterodactyl panel first!${NC}"; sleep 2; return; }
    wget "https://github.com/BlueprintFramework/framework/releases/latest/download/release.zip" -O "$PTERODACTYL_DIRECTORY/release.zip"
    unzip -o release.zip

    echo -e "\n ${Y}[3/6] Installing full dependencies...${NC}"
    apt install -y ca-certificates curl git gnupg unzip wget zip

    echo -e "\n ${Y}[4/6] Adding Node.js v22 repository...${NC}"
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
    apt update && apt install -y nodejs

    echo -e "\n ${Y}[5/6] Installing Yarn & Node dependencies...${NC}"
    cd "$PTERODACTYL_DIRECTORY"
    npm i -g yarn
    yarn install

    echo -e "\n ${Y}[6/6] Configuring Blueprint...${NC}"
    touch "$PTERODACTYL_DIRECTORY/.blueprintrc"
    echo 'WEBUSER="www-data";
OWNERSHIP="www-data:www-data";
USERSHELL="/bin/bash";' > "$PTERODACTYL_DIRECTORY/.blueprintrc"
    chmod +x "$PTERODACTYL_DIRECTORY/blueprint.sh"

    echo ""
    echo -e " ${DG}────────────────────────────────────────────────────────────${NC}"
    echo -e " ${G}✔ Blueprint installed! Running blueprint.sh...${NC}"
    echo -e " ${DG}────────────────────────────────────────────────────────────${NC}"
    echo ""
    bash "$PTERODACTYL_DIRECTORY/blueprint.sh"

    echo ""
    read -n 1 -s -r -p "  Press any key to return..."
}

while true; do
    header
    echo -e " ${Y}SELECT AN OPTION:${NC}"
    echo -e " ${DG}────────────────────────────────────────────────────────────${NC}"
    echo -e " ${P}[1]${NC} ${W}Install Blueprint${NC}   ${DG}:: Blueprint Framework Installer${NC}"
    echo -e " ${P}[2]${NC} ${W}Extensions${NC}          ${DG}:: Install / Remove Extensions${NC}"
    echo -e " ${DG}────────────────────────────────────────────────────────────${NC}"
    echo -e " ${R}[0]${NC} ${DG}Back${NC}"
    echo -e " ${DG}────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -ne " ${C}➜${NC} ${W}Enter Option (0-2):${NC} "
    read -r opt

    case $opt in
        1) install_blueprint ;;
        2) bash <(curl -fsSL "$BASE/thame/Extension2.sh") ;;
        0) exit 0 ;;
        *) echo -e " ${R}✘ Invalid option.${NC}"; sleep 0.8 ;;
    esac
done
