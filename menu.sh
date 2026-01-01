#!/bin/bash
# Main Menu - SIGMA VPN (Optimized for Debian 12)

# Colors
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
PURPLE='\e[1;35m'
CYAN='\e[1;36m'
NC='\e[0m'

# Get System Info
MYIP=$(hostname -I | awk '{print $1}')
if [ -f /etc/xray/domain ]; then
    DOMAIN=$(cat /etc/xray/domain)
else
    DOMAIN="No Domain Detected"
fi

# Function to clear RAM cache (Debian 12 compatible)
function clearcache() {
    echo "Clearing RAM Cache..."
    sync && echo 3 > /proc/sys/vm/drop_caches
    echo -e "${GREEN}RAM Cache cleared successfully!${NC}"
    sleep 1
    menu
}

# Main Menu Loop
function menu() {
clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}            ⛓️ SIGMA VPN PREMIUM ⛓️            ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${BLUE}OS      :${NC} $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d\" -f2)"
echo -e "  ${BLUE}IP      :${NC} $MYIP"
echo -e "  ${BLUE}DOMAIN  :${NC} $DOMAIN"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e ""
echo -e "  ${YELLOW}[1]${NC} Menu Vmess"
echo -e "  ${YELLOW}[2]${NC} Menu Vless"
echo -e "  ${YELLOW}[3]${NC} Menu Trojan"
echo -e "  ${YELLOW}[4]${NC} Menu Shadowsocks (WS)"
echo -e "  ${YELLOW}[5]${NC} Menu WireGuard"
echo -e "  ${YELLOW}[6]${NC} Menu Tools"
echo -e "  ${YELLOW}[7]${NC} Status Service"
echo -e "  ${YELLOW}[8]${NC} Clear RAM Cache"
echo -e "  ${YELLOW}[9]${NC} Reboot VPS"
echo -e "  ${RED}[x]${NC} Exit"
echo -e ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
read -p "👉 Pilih menu: " opt

case $opt in
  1) m-vmess ;;
  2) m-vless ;;
  3) m-trojan ;;
  4) m-ssws ;;
  5) m-wg ;;
  6) tools-menu ;;
  7) 
    # Logic for status service
    if command -v running &> /dev/null; then running; else systemctl status xray; fi
    ;;
  8) clearcache ;;
  9) reboot ;;
  x) exit ;;
  *) echo -e "${RED}❌ Pilihan tidak valid!${NC}" ; sleep 1 ; menu ;;
esac
}

# Execute menu
menu
