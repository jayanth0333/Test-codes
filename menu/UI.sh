#!/usr/bin/env bash

P='\033[1;38;5;201m'
VIOLET='\033[1;38;5;135m'
G='\033[1;38;5;82m'
R='\033[1;38;5;196m'
Y='\033[1;38;5;220m'
C='\033[1;38;5;51m'
W='\033[1;38;5;255m'
DG='\033[0;38;5;244m'
BG='\033[48;5;236m'
NC='\033[0m'

get_metrics() {
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{printf "%.0f", $2+$4}' 2>/dev/null || echo "?")
    RAM=$(free | grep Mem | awk '{printf "%.0f", $3*100/$2}' 2>/dev/null || echo "?")
    UPT=$(uptime -p | sed 's/up //' 2>/dev/null || echo "?")
    HOST=$(hostname)
}

render_banner() {
    COLS=$(tput cols 2>/dev/null || echo 80)
    if [ "$COLS" -ge 88 ]; then
        echo -e "${C}        ██╗ █████╗ ██╗   ██╗ █████╗ ███╗   ██╗████████╗██╗  ██╗    ██╗  ██╗██╗   ██╗██████╗ ${NC}"
        echo -e "${C}        ██║██╔══██╗╚██╗ ██╔╝██╔══██╗████╗  ██║╚══██╔══╝██║  ██║    ██║  ██║██║   ██║██╔══██╗${NC}"
        echo -e "${P}        ██║███████║ ╚████╔╝ ███████║██╔██╗ ██║   ██║   ███████║    ███████║██║   ██║██████╔╝${NC}"
        echo -e "${P}  ██    ██║██╔══██║  ╚██╔╝  ██╔══██║██║╚██╗██║   ██║   ██╔══██║    ██╔══██║██║   ██║██╔══██╗${NC}"
        echo -e "${Y}  ╚██████╔╝██║  ██║   ██║   ██║  ██║██║ ╚████║   ██║   ██║  ██║    ██║  ██║╚██████╔╝██████╔╝${NC}"
        echo -e "${Y}   ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝${NC}"
    elif [ "$COLS" -ge 62 ]; then
        echo -e "${C}      ██╗ █████╗ ██╗   ██╗ █████╗ ███╗   ██╗████████╗██╗  ██╗${NC}"
        echo -e "${C}      ██║██╔══██╗╚██╗ ██╔╝██╔══██╗████╗  ██║╚══██╔══╝██║  ██║${NC}"
        echo -e "${P}      ██║███████║ ╚████╔╝ ███████║██╔██╗ ██║   ██║   ███████║${NC}"
        echo -e "${P} ██   ██║██╔══██║  ╚██╔╝  ██╔══██║██║╚██╗██║   ██║   ██╔══██║${NC}"
        echo -e "${Y} ╚██████╔╝██║  ██║   ██║   ██║  ██║██║ ╚████║   ██║   ██║  ██║${NC}"
        echo -e "${Y}  ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝${NC}"
        echo -e "           ${P}★${NC} ${W}JAYANTH HUB${NC} ${DG}— OBSIDIAN NEXT GEN${NC}"
    else
        echo -e " ${P}★★★ JAYANTH HUB ★★★${NC}"
    fi
    echo -e "              ${DG}JAYANTH EDITION — OBSIDIAN NEXT GEN${NC}"
}

render_ui() {
    clear
    get_metrics
    echo -e " ${C}▐${NC}${BG} $HOST ${NC}${C}▌${NC}  ${P}▐${NC}${BG} ⏱ $UPT ${NC}${P}▌${NC}  ${G}▐${NC}${BG} CPU ${CPU}% ${NC}${G}▌${NC}  ${Y}▐${NC}${BG} RAM ${RAM}% ${NC}${Y}▌${NC}"
    echo -e ""
    render_banner
    echo -e ""
    echo -e " ${DG}────────────────────────────────────────────────────────────${NC}"
    echo -e ""
    echo -e " ${C}◉ SERVICES${NC}"
    echo -e " ${DG}├─${NC} ${P}[1]${NC} ${W}Panel${NC}       ${DG}:: Pterodactyl Install / Uninstall${NC}"
    echo -e " ${DG}├─${NC} ${P}[2]${NC} ${W}Themes${NC}      ${DG}:: Blueprint UI Themes${NC}"
    echo -e " ${DG}└─${NC} ${P}[3]${NC} ${W}Extensions${NC}  ${DG}:: Blueprint Extensions${NC}"
    echo -e ""
    echo -e " ${DG}────────────────────────────────────────────────────────────${NC}"
    echo -e " ${DG}└─${NC} ${R}[0]${NC} ${DG}Exit${NC}"
    echo -e " ${DG}────────────────────────────────────────────────────────────${NC}"
    echo -e ""
    echo -ne " ${C}➜${NC} ${W}Enter Option (0-3):${NC} "
}

while true; do
    render_ui
    read -r opt
    case $opt in
        1) bash <(curl -fsSL https://raw.githubusercontent.com/jayanth0333/Test-codes/main/panel/run.sh) ;;
        2) bash <(curl -fsSL https://raw.githubusercontent.com/jayanth0333/Test-codes/main/thame/thames.sh) ;;
        3) bash <(curl -fsSL https://raw.githubusercontent.com/jayanth0333/Test-codes/main/thame/Extension2.sh) ;;
        0)
            echo -e "\n ${R}● DISCONNECTED${NC}  Goodbye, JAYANTH."
            exit 0 ;;
        *)
            echo -e " ${R}✘ Invalid option.${NC}"; sleep 0.8 ;;
    esac
done
