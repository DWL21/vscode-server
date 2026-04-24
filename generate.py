#!/usr/bin/env python3
import yaml
import os

PROFILES_FILE = "profiles.yml"
COMPOSE_FILE = "docker-compose.yml"
DATA_DIR = "data"
NGINX_CONF = "nginx/conf.d/simplyimg.conf"
DOMAIN = "simplyimg.com"

NGINX_TEMPLATE = """\
server {{
    listen 80;
    server_name {domain};
    return 301 https://$host$request_uri;
}}

server {{
    listen 443 ssl;
    server_name {domain};

    ssl_certificate     /etc/letsencrypt/live/{domain}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/{domain}/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 86400;

{locations}}}
"""

LOCATION_BLOCK = """\
    location /{name}/ {{
        proxy_pass http://vscode-{name}:8080/{name}/;
    }}

"""


def load_profiles():
    with open(PROFILES_FILE) as f:
        return yaml.safe_load(f)["profiles"]


def ensure_data_dirs(profiles):
    for p in profiles:
        path = os.path.join(DATA_DIR, p["name"])
        os.makedirs(path, mode=0o755, exist_ok=True)
    print("[+] data/ directories ready")


def generate_compose(profiles):
    services = {
        "nginx": {
            "image": "nginx:alpine",
            "ports": ["80:80", "443:443"],
            "volumes": [
                "./nginx/conf.d:/etc/nginx/conf.d:ro",
                "/etc/letsencrypt:/etc/letsencrypt:ro",
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
            "user": "1000:1000",
            "environment": {
                "PASSWORD": p["password"],
                "USERNAME": name,
            },
            "volumes": [f"./data/{name}:/home/coder"],
            "networks": ["vscode-net"],
            "restart": "unless-stopped",
        }

    compose = {
        "services": services,
        "networks": {"vscode-net": {"driver": "bridge"}},
    }

    with open(COMPOSE_FILE, "w") as f:
        yaml.dump(compose, f, default_flow_style=False, allow_unicode=True)
    print(f"[+] {COMPOSE_FILE} generated ({len(profiles)} user(s))")


def generate_nginx(profiles):
    os.makedirs(os.path.dirname(NGINX_CONF), exist_ok=True)
    locations = "".join(LOCATION_BLOCK.format(name=p["name"]) for p in profiles)
    config = NGINX_TEMPLATE.format(domain=DOMAIN, locations=locations)
    with open(NGINX_CONF, "w") as f:
        f.write(config)
    print(f"[+] {NGINX_CONF} generated")


def print_summary(profiles):
    print(f"\n{'─'*50}")
    for p in profiles:
        print(f"  {p['name']:12s}  https://{DOMAIN}/{p['name']}/")
    print(f"{'─'*50}\n")


if __name__ == "__main__":
    profiles = load_profiles()
    ensure_data_dirs(profiles)
    generate_compose(profiles)
    generate_nginx(profiles)
    print_summary(profiles)
