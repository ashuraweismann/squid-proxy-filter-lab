#!/bin/bash

PROXY="http://10.50.225.222:3128"

echo "======================================"
echo " Squid Proxy Filter Lab - Test"
echo "======================================"

echo
echo "[1] Checking Squid service..."

if systemctl is-active --quiet squid; then
    echo "[+] Squid service is running."
else
    echo "[!] Squid service is NOT running."
    echo
    echo "Try:"
    echo "  sudo systemctl status squid"
    echo "  sudo journalctl -xeu squid.service"
    exit 1
fi

echo
echo "[2] Checking proxy port..."

if ss -lnt | grep -q ":3128"; then
    echo "[+] Squid is listening on port 3128."
else
    echo "[!] Nothing is listening on port 3128."
    exit 1
fi

echo
echo "[3] Testing allowed website..."

ALLOWED_URL="https://example.org"

HTTP_CODE=$(curl \
    --silent \
    --output /dev/null \
    --write-out "%{http_code}" \
    --proxy "$PROXY" \
    --max-time 10 \
    "$ALLOWED_URL")

if [[ "$HTTP_CODE" =~ ^2|^3 ]]; then
    echo "[+] Allowed request succeeded."
    echo "    URL: $ALLOWED_URL"
    echo "    HTTP status: $HTTP_CODE"
else
    echo "[!] Allowed request failed."
    echo "    HTTP status: $HTTP_CODE"
fi

echo
echo "[4] Testing blocked website..."

BLOCKED_URL="https://www.reddit.com"

HTTP_CODE=$(curl \
    --silent \
    --output /dev/null \
    --write-out "%{http_code}" \
    --proxy "$PROXY" \
    --max-time 10 \
    "$BLOCKED_URL")

if [[ "$HTTP_CODE" == "403" ]]; then
    echo "[+] Blocked request was denied correctly."
    echo "    URL: $BLOCKED_URL"
    echo "    HTTP status: $HTTP_CODE"
else
    echo "[!] Block test returned:"
    echo "    HTTP status: $HTTP_CODE"
    echo
    echo "Check:"
    echo "  /etc/squid/blocked_domains.txt"
    echo "  /etc/squid/squid.conf"
fi

echo
echo "[5] Recent Squid log entries:"
echo "--------------------------------------"

sudo tail -n 10 /var/log/squid/access.log

echo
echo "======================================"
echo " Test completed"
echo "======================================"