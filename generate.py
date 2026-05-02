#!/usr/bin/env python3
import yaml
import os

PROFILES_FILE = "profiles.yml"
COMPOSE_FILE = "docker-compose.yml"
DATA_DIR = "data"
NGINX_CONF_DIR = "nginx/conf.d"
BASE_DOMAIN = "simplyimg.com"

NGINX_VHOST_TEMPLATE = """\
server {{
    listen 80;
    server_name {subdomain};
    return 301 https://$host$request_uri;
}}

server {{
    listen 443 ssl;
    server_name {subdomain};

    ssl_certificate     /etc/ssl/cloudflare/simplyimg.com.pem;
    ssl_certificate_key /etc/ssl/cloudflare/simplyimg.com.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    # Docker embedded DNS — 컨테이너 재생성 시 IP 변경을 자동 반영
    resolver 127.0.0.11 valid=10s ipv6=off;

    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 86400;

    location / {{
        set $upstream vscode-{name};
        proxy_pass http://$upstream:8080;
    }}
}}
"""


def load_profiles():
    with open(PROFILES_FILE) as f:
        return yaml.safe_load(f)["profiles"]


def ensure_data_dirs(profiles):
    for p in profiles:
        path = os.path.join(DATA_DIR, p["name"])
        os.makedirs(path, mode=0o755, exist_ok=True)
        try:
            os.chown(path, 1000, 1000)
        except PermissionError:
            print(f"[!] Cannot chown {path} — run as root or sudo if containers fail to start")
    print("[+] data/ directories ready")


def generate_compose(profiles):
    services = {
        "nginx": {
            "image": "nginx:alpine",
            "ports": ["80:80", "443:443"],
            "volumes": [
                "./nginx/conf.d:/etc/nginx/conf.d:ro",
                "/etc/ssl/cloudflare:/etc/ssl/cloudflare:ro",
            ],
            "networks": ["vscode-net"],
            "restart": "unless-stopped",
            "depends_on": [p["name"] for p in profiles],
        }
    }

    for p in profiles:
        name = p["name"]
        services[name] = {
            "build": ".",
            "container_name": f"vscode-{name}",
            "hostname": name,
            "user": "1000:1000",
            "environment": {
                "PASSWORD": p["password"],
                "USERNAME": name,
            },
            "volumes": [f"./data/{name}:/home/coder"],
            "networks": ["vscode-net"],
            "restart": "unless-stopped",
            "mem_limit": "4g",
            "mem_reservation": "256m",
        }

    compose = {
        "services": services,
        "networks": {"vscode-net": {"driver": "bridge"}},
    }

    with open(COMPOSE_FILE, "w") as f:
        yaml.dump(compose, f, default_flow_style=False, allow_unicode=True)
    print(f"[+] {COMPOSE_FILE} generated ({len(profiles)} user(s))")


NGINX_MAP_CONF = """\
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}
"""


def generate_nginx(profiles):
    os.makedirs(NGINX_CONF_DIR, exist_ok=True)

    map_path = os.path.join(NGINX_CONF_DIR, "00-map.conf")
    with open(map_path, "w") as f:
        f.write(NGINX_MAP_CONF)

    for p in profiles:
        name = p["name"]
        subdomain = f"{name}.{BASE_DOMAIN}"
        config = NGINX_VHOST_TEMPLATE.format(name=name, subdomain=subdomain)
        out_path = os.path.join(NGINX_CONF_DIR, f"{name}.conf")
        with open(out_path, "w") as f:
            f.write(config)
    print(f"[+] nginx/conf.d/ generated ({len(profiles)} vhosts)")


def print_summary(profiles):
    print(f"\n{'─'*50}")
    for p in profiles:
        print(f"  {p['name']:12s}  https://{p['name']}.{BASE_DOMAIN}/")
    print(f"{'─'*50}\n")


if __name__ == "__main__":
    profiles = load_profiles()
    ensure_data_dirs(profiles)
    generate_compose(profiles)
    generate_nginx(profiles)
    print_summary(profiles)
