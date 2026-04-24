#!/bin/bash
# Cloudflare DNS challenge로 SSL 인증서 발급
# 사전 필요: certbot, python3-certbot-dns-cloudflare
#
# 설치: sudo apt install certbot python3-certbot-dns-cloudflare
# Cloudflare API Token: https://dash.cloudflare.com/profile/api-tokens
#   권한: Zone:DNS:Edit, Zone:Zone:Read

set -e

BASE_DOMAIN="simplyimg.com"
EMAIL="nggus5@gmail.com"
CF_CREDENTIALS="/etc/letsencrypt/cloudflare.ini"
PROFILES_FILE="$(dirname "$0")/../profiles.yml"

if [ ! -f "$CF_CREDENTIALS" ]; then
    echo "[!] Cloudflare credentials not found at $CF_CREDENTIALS"
    echo "    Create it:"
    echo "    echo 'dns_cloudflare_api_token = YOUR_TOKEN' | sudo tee $CF_CREDENTIALS"
    echo "    sudo chmod 600 $CF_CREDENTIALS"
    exit 1
fi

# profiles.yml에서 이름 목록 추출
NAMES=$(python3 -c "
import yaml, sys
with open('$PROFILES_FILE') as f:
    profiles = yaml.safe_load(f)['profiles']
print('\n'.join(p['name'] for p in profiles))
")

for NAME in $NAMES; do
    SUBDOMAIN="${NAME}.${BASE_DOMAIN}"
    echo "[+] Issuing certificate for ${SUBDOMAIN}..."
    sudo certbot certonly \
        --dns-cloudflare \
        --dns-cloudflare-credentials "$CF_CREDENTIALS" \
        -d "$SUBDOMAIN" \
        --email "$EMAIL" \
        --agree-tos \
        --non-interactive
    echo "[+] Done: ${SUBDOMAIN}"
done

echo ""
echo "Reload nginx:"
echo "  docker compose exec nginx nginx -s reload"
