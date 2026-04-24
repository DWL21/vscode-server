#!/bin/bash
# Cloudflare DNS challenge로 SSL 인증서 발급
# 사전 필요: certbot, python3-certbot-dns-cloudflare
#
# 설치: sudo apt install certbot python3-certbot-dns-cloudflare
# Cloudflare API Token: https://dash.cloudflare.com/profile/api-tokens
#   권한: Zone:DNS:Edit, Zone:Zone:Read

set -e

DOMAIN="simplyimg.com"
EMAIL="nggus5@gmail.com"
CF_CREDENTIALS="/etc/letsencrypt/cloudflare.ini"

if [ ! -f "$CF_CREDENTIALS" ]; then
    echo "[!] Cloudflare credentials not found at $CF_CREDENTIALS"
    echo "    Create it:"
    echo "    echo 'dns_cloudflare_api_token = YOUR_TOKEN' | sudo tee $CF_CREDENTIALS"
    echo "    sudo chmod 600 $CF_CREDENTIALS"
    exit 1
fi

echo "[+] Issuing certificate for ${DOMAIN}..."
sudo certbot certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials "$CF_CREDENTIALS" \
    -d "${DOMAIN}" \
    --email "$EMAIL" \
    --agree-tos \
    --non-interactive

echo ""
echo "[+] Done. Reload nginx inside Docker:"
echo "    docker compose exec nginx nginx -s reload"
