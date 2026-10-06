#!/bin/bash

set -e

echo "======================================"
echo " Squid Proxy Filter Lab - Installation"
echo "======================================"

# Require root privileges
if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run this script with sudo."
    echo "    Example: sudo ./install-squid.sh"
    exit 1
fi

PROXY_IP="10.50.225.222"
PROXY_PORT="3128"
LAB_NETWORK="10.50.225.0/24"

echo "[+] Updating package lists..."
apt update

echo "[+] Installing Squid..."
apt install -y squid

echo "[+] Backing up existing Squid configuration..."

if [ -f /etc/squid/squid.conf ]; then
    cp /etc/squid/squid.conf \
       /etc/squid/squid.conf.backup.$(date +%Y%m%d-%H%M%S)
fi

echo "[+] Creating blocked domain list..."

cat > /etc/squid/blocked_domains.txt << 'EOF'
.facebook.com
.instagram.com
.twitter.com
.x.com
.tiktok.com
.reddit.com
.linkedin.com
.pinterest.com
.threads.net

.chatgpt.com
.openai.com
.claude.ai
.anthropic.com
.gemini.google.com
.perplexity.ai
.grok.com
.copilot.microsoft.com
.character.ai
.you.com
EOF

echo "[+] Creating Squid configuration..."

cat > /etc/squid/squid.conf << EOF
# ==========================================
# Squid Proxy Filter Lab
# ==========================================

# Proxy listening address
http_port ${PROXY_IP}:${PROXY_PORT}

# Lab client network
acl lab_network src ${LAB_NETWORK}

# Blocked domains
acl blocked_domains dstdomain "/etc/squid/blocked_domains.txt"

# Deny blocked domains first
http_access deny blocked_domains

# Allow clients from the lab network
http_access allow lab_network

# Deny everything else
http_access deny all
EOF

echo "[+] Validating Squid configuration..."

squid -k parse

echo "[+] Initializing Squid cache directories..."

squid -z

echo "[+] Enabling Squid at boot..."

systemctl enable squid

echo "[+] Restarting Squid..."

systemctl restart squid

echo
echo "======================================"
echo " Installation completed successfully!"
echo "======================================"

echo
echo "Proxy:"
echo "  IP   : ${PROXY_IP}"
echo "  Port : ${PROXY_PORT}"

echo
echo "Blocked domains:"
echo "  /etc/squid/blocked_domains.txt"

echo
echo "Access log:"
echo "  /var/log/squid/access.log"

echo
echo "Service status:"
systemctl --no-pager --full status squid