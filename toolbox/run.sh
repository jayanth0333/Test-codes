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

pause() { echo ""; read -n 1 -s -r -p "  Press any key to continue..."; echo ""; }

header() {
    clear
    USER=$(whoami); HOST=$(hostname)
    RAM=$(free -h | awk '/Mem:/ {print $3"/"$2}')
    LOAD=$(uptime | awk -F'load average:' '{print $2}' | xargs)
    IP=$(curl -s --max-time 3 ifconfig.me 2>/dev/null || echo "N/A")
    echo -e "${VIOLET}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${VIOLET}║${NC}         ${P}★ JAYANTH HUB${NC} ${DG}::${NC} ${C}SERVER TOOLBOX${NC}              ${VIOLET}║${NC}"
    echo -e "${VIOLET}╠════════════════════════════════════════════════════════════╣${NC}"
    printf "${VIOLET}║${NC} ${G}User:${NC} %-10s ${G}Host:${NC} %-24s${VIOLET}║${NC}\n" "$USER" "$HOST"
    printf "${VIOLET}║${NC} ${Y}RAM:${NC}  %-10s ${Y}Load:${NC} %-24s${VIOLET}║${NC}\n" "$RAM" "$LOAD"
    printf "${VIOLET}║${NC} ${C}IP:${NC}   %-47s${VIOLET}║${NC}\n" "$IP"
    echo -e "${VIOLET}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

while true; do
    header
    echo -e " ${C}[ ACCESS & NETWORK ]${NC}"
    echo -e "  ${P}1)${NC} Root Access         ${DG}:: Enable Root/Sudo${NC}"
    echo -e "  ${P}2)${NC} Tailscale           ${DG}:: Mesh VPN (Official)${NC}"
    echo -e "  ${P}3)${NC} Zerotier            ${DG}:: VPN (Official)${NC}"
    echo -e "  ${P}4)${NC} Cloudflared         ${DG}:: Cloudflare Tunnel${NC}"
    echo ""
    echo -e " ${Y}[ SYSTEM OPERATIONS ]${NC}"
    echo -e "  ${P}5)${NC} System Info         ${DG}:: Live Specs & Status${NC}"
    echo -e "  ${P}6)${NC} Port Forward        ${DG}:: LocalToNet${NC}"
    echo ""
    echo -e " ${G}[ GUI & REMOTE ]${NC}"
    echo -e "  ${P}7)${NC} Web Terminal        ${DG}:: ttyd Browser Shell${NC}"
    echo -e "  ${P}8)${NC} RDP Installer       ${DG}:: XRDP Remote Desktop${NC}"
    echo -e "  ${P}9)${NC} SSL Setup           ${DG}:: Certbot (Let's Encrypt)${NC}"
    echo ""
    echo -e " ${DG}────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${R}0)${NC} ${DG}Back / Exit${NC}"
    echo -e " ${DG}────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -ne " ${C}➜${NC} ${W}Select Tool [0-9]:${NC} "
    read -r t

    case $t in
        1)
            clear; echo -e "\n ${Y}⚙ ENABLING ROOT ACCESS...${NC}\n"
            echo "root:root" | chpasswd 2>/dev/null || true
            sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config 2>/dev/null
            sed -i 's/PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config 2>/dev/null
            sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config 2>/dev/null
            sed -i 's/PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config 2>/dev/null
            systemctl restart sshd 2>/dev/null || service ssh restart 2>/dev/null
            echo -e "\n ${G}✔ Root enabled. Password: root${NC}"; pause ;;
        2)
            clear; echo -e "\n ${Y}⚙ INSTALLING TAILSCALE...${NC}\n"
            curl -fsSL https://tailscale.com/install.sh | sh
            echo -e "\n ${G}✔ Run: tailscale up${NC}"; pause ;;
        3)
            clear; echo -e "\n ${Y}⚙ INSTALLING ZEROTIER...${NC}\n"
            curl -s https://install.zerotier.com | bash
            echo -e "\n ${G}✔ Run: zerotier-cli join <networkID>${NC}"; pause ;;
        4)
            clear; echo -e "\n ${Y}⚙ INSTALLING CLOUDFLARED...${NC}\n"
            curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
            dpkg -i cloudflared.deb && rm -f cloudflared.deb
            echo -e "\n ${G}✔ Run: cloudflared tunnel login${NC}"; pause ;;
        5)
            clear
            echo -e "\n ${C}════════════════════════════════════════${NC}"
            echo -e " ${P}★ SYSTEM INFO — JAYANTH HUB${NC}"
            echo -e " ${C}════════════════════════════════════════${NC}"
            echo -e " ${G}OS      :${NC} $(lsb_release -d 2>/dev/null | cut -f2 || uname -o)"
            echo -e " ${G}Kernel  :${NC} $(uname -r)"
            echo -e " ${G}Uptime  :${NC} $(uptime -p)"
            echo -e " ${G}CPU     :${NC} $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
            echo -e " ${G}Cores   :${NC} $(nproc)"
            echo -e " ${G}RAM     :${NC} $(free -h | awk '/Mem:/{print $2}') total | $(free -h | awk '/Mem:/{print $3}') used"
            echo -e " ${G}Disk    :${NC} $(df -h / | awk 'NR==2{print $2}') total | $(df -h / | awk 'NR==2{print $3}') used"
            echo -e " ${G}Pub IP  :${NC} $(curl -s --max-time 3 ifconfig.me)"
            echo -e " ${G}Loc IP  :${NC} $(hostname -I | awk '{print $1}')"
            echo -e " ${C}════════════════════════════════════════${NC}"
            pause ;;
        6)
            clear; echo -e "\n ${Y}⚙ INSTALLING LOCALTONET...${NC}\n"
            curl -s https://localtonet.com/download/linux_amd64 -o /usr/local/bin/localtonet
            chmod +x /usr/local/bin/localtonet
            echo -e "\n ${G}✔ Run: localtonet -token <your_token>${NC}"
            echo -e " ${DG}Get token: https://localtonet.com${NC}"; pause ;;
        7)
            clear; echo -e "\n ${Y}⚙ INSTALLING TTYD (Web Terminal)...${NC}\n"
            apt-get install -y ttyd 2>/dev/null || \
            { curl -L https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.x86_64 -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd; }
            echo -e "\n ${G}✔ Run: ttyd -p 7681 bash${NC}"
            echo -e " ${DG}Access: http://<your-ip>:7681${NC}"; pause ;;
        8)
            clear; echo -e "\n ${Y}⚙ INSTALLING XRDP...${NC}\n"
            apt-get update -y && apt-get install -y xrdp
            systemctl enable xrdp && systemctl start xrdp
            echo -e "\n ${G}✔ XRDP running on port 3389${NC}"; pause ;;
        9)
            clear; echo -e "\n ${Y}⚙ SSL SETUP (Certbot)...${NC}\n"
            apt-get install -y certbot
            echo -ne "\n ${W}Enter domain (e.g. panel.example.com):${NC} "; read -r DOMAIN
            echo -ne " ${W}Enter email:${NC} "; read -r EMAIL
            certbot certonly --standalone -d "$DOMAIN" --email "$EMAIL" --agree-tos --non-interactive
            echo -e "\n ${G}✔ Certs at /etc/letsencrypt/live/$DOMAIN/${NC}"; pause ;;
        0) exit 0 ;;
        *) echo -e " ${R}✘ Invalid option.${NC}"; sleep 0.8 ;;
    esac
done
