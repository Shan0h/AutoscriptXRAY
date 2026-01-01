#!/bin/bash
# Setup Xray Core - optimized for Debian 12
# by znand-dev / Gemini

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}▶️ Memulai instalasi Xray-core pada Debian 12...${NC}"
sleep 1

# 1. Update & Install Dependencies
# Added 'net-tools' and 'dbus' for better service management on Debian 12
apt update -y
export DEBIAN_FRONTEND=noninteractive
apt install -y socat curl cron jq unzip gnupg coreutils lsof net-tools -qq

# 2. Download Xray-core terbaru
mkdir -p /etc/xray /var/log/xray /usr/local/bin

echo -e "${GREEN}⬇️ Download Xray-core...${NC}"
# Use the correct binary for 64-bit architecture
wget -q -O /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o /tmp/xray.zip -d /usr/local/bin/
chmod +x /usr/local/bin/xray
rm -f /tmp/xray.zip

# 3. Konfigurasi domain
# Check multiple possible locations for the domain file
if [[ -f /root/domain ]]; then
  domain=$(cat /root/domain)
elif [[ -f /etc/xray/domain ]]; then
  domain=$(cat /etc/xray/domain)
else
  echo -e "${RED}[ERROR] File domain tidak ditemukan! Masukkan domain secara manual.${NC}"
  read -rp "Domain: " domain
  echo "$domain" > /root/domain
fi

echo "$domain" > /etc/xray/domain

# 4. Install & issue cert via acme.sh
# Debian 12 requires explicit path handling for root environment
if [ ! -f "$HOME/.acme.sh/acme.sh" ]; then
  echo -e "${GREEN}🔐 Menginstall acme.sh...${NC}"
  curl https://get.acme.sh | sh -s email=admin@$domain
fi

# Define acme command shortcut
ACME_BIN="$HOME/.acme.sh/acme.sh"

# Stop existing services that might use port 80 for certificate issuance
systemctl stop nginx 2>/dev/null
systemctl stop xray 2>/dev/null

echo -e "${GREEN}🔐 Issuing SSL Certificate for $domain...${NC}"
$ACME_BIN --set-default-ca --server letsencrypt
$ACME_BIN --register-account -m admin@$domain
$ACME_BIN --issue --standalone -d $domain --keylength ec-256

# Install certificate to Xray directory
$ACME_BIN --install-cert -d $domain \
  --key-file /etc/xray/private.key \
  --fullchain-file /etc/xray/cert.crt \
  --ecc

# 5. Deploy config.json
cat > /etc/xray/config.json <<EOF
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/xray/cert.crt",
              "keyFile": "/etc/xray/private.key"
            }
          ]
        },
        "wsSettings": {
          "path": "/vmess"
        }
      },
      "tag": "vmess-tls"
    },
    {
      "port": 80,
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/vmess"
        }
      },
      "tag": "vmess-nontls"
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "blocked"
    }
  ]
}
EOF

# 6. Setup systemd service (Modified for Debian 12 stability)
cat > /etc/systemd/system/xray.service <<EOF
[Unit]
Description=Xray Service for Debian 12
Documentation=https://xray.dev/
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray -config /etc/xray/config.json
Restart=on-failure
RestartSec=3s
LimitNPROC=1000000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

# 7. Start Service
systemctl daemon-reload
systemctl enable xray
systemctl restart xray

# 8. Logging
grep -q "XRAY TLS" /root/log-install.txt || echo "XRAY TLS         : 443" >> /root/log-install.txt
grep -q "XRAY None TLS" /root/log-install.txt || echo "XRAY None TLS    : 80" >> /root/log-install.txt

# Output final
echo -e "${GREEN}✅ Xray-core berhasil di-install dan dikonfigurasi!${NC}"
echo -e "${GREEN}📂 Config: /etc/xray/config.json${NC}"
systemctl status xray --no-pager | grep Active
