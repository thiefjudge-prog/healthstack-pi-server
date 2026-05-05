# healthstack-pi-server

Ops companion repo for deploying [HealthStack Pro](https://github.com/RubenGZ/Health_Stack)
on a Raspberry Pi 3B. Three exposure phases, one variable to switch between them.

## Hardware

| | |
|---|---|
| Model | Raspberry Pi 3B |
| CPU | ARM Cortex-A53 64-bit |
| RAM | 1 GB |
| Storage | 64 GB SD card |
| OS | Raspberry Pi OS 64-bit (Bookworm) |

## Exposure Phases

| `EXPOSE_MODE` | URL | Use case |
|---|---|---|
| `quick` | Random `*.trycloudflare.com` | First tests — **no account needed** |
| `cloudflare` | Stable Cloudflare subdomain | Ongoing dev / demo |
| `domain` | Your own domain + HTTPS | Production |

**Switching phase** = edit one line in `.env.pi` + `bash scripts/update.sh`.

---

## First-time Setup

### Step 1 — Prepare the OS

```bash
git clone https://github.com/thiefjudge-prog/healthstack-pi-server.git
cd healthstack-pi-server
bash scripts/01-system.sh
sudo reboot
```

### Step 2 — Install Docker

```bash
bash scripts/02-docker.sh
newgrp docker   # or log out and back in
```

### Step 3 — Deploy (Quick Tunnel — no account needed)

```bash
bash scripts/03-deploy.sh
```

The script will pause and ask you to fill in two files:

**`~/health-stack/.env.pi`** — at minimum set:
```bash
EXPOSE_MODE=quick
POSTGRES_PASSWORD=choose_a_strong_password
REDIS_PASSWORD=choose_a_strong_password
```

**`~/health-stack/backend/.env`** — generate RSA keys and set:
```bash
# Generate keys on any machine with openssl:
#   openssl genrsa -out private.pem 2048
#   openssl rsa -in private.pem -pubout -out public.pem
JWT_PRIVATE_KEY_PEM=...
JWT_PUBLIC_KEY_PEM=...
HEALTH_LINK_MASTER_KEY=...   # 64 hex chars: python3 -c "import secrets; print(secrets.token_hex(32))"
ALLOWED_ORIGINS=https://xxx.trycloudflare.com   # update after tunnel starts
```

Then re-run:
```bash
bash scripts/03-deploy.sh
```

**Find the Quick Tunnel URL** (appears ~30s after containers start):
```bash
docker logs healthstack_tunnel_quick 2>&1 | grep trycloudflare
```

---

## Migrate to Cloudflare Named Tunnel (stable URL)

```bash
# 1. Follow the guide to get your token
bash scripts/04-cloudflare.sh

# 2. Edit .env.pi
nano ~/health-stack/.env.pi
#   EXPOSE_MODE=cloudflare
#   CLOUDFLARE_TUNNEL_TOKEN=<your-token>

# 3. Update backend/.env
nano ~/health-stack/backend/.env
#   ALLOWED_ORIGINS=https://your-tunnel-url.cfargotunnel.com

# 4. Restart
bash scripts/update.sh
```

---

## Migrate to Custom Domain

```bash
# 1. Point your domain's DNS A record to your Pi's public IP

# 2. Edit .env.pi
nano ~/health-stack/.env.pi
#   EXPOSE_MODE=domain
#   DOMAIN=yourdomain.com

# 3. Update ALLOWED_ORIGINS in backend/.env
nano ~/health-stack/backend/.env
#   ALLOWED_ORIGINS=https://yourdomain.com

# 4. Restart
bash scripts/update.sh

# 5. Obtain first certificate (run once)
docker exec healthstack_certbot certbot certonly \
  --webroot -w /var/www/certbot \
  -d yourdomain.com \
  --email your@email.com \
  --agree-tos --no-eff-email
```

Renewal happens automatically every 12 hours inside the certbot container.

---

## Day-to-day operations

```bash
# Update app to latest
bash ~/healthstack-pi-server/scripts/update.sh

# Check container status
docker compose -f ~/health-stack/docker-compose.pi.yml ps

# View backend logs
docker logs healthstack_backend -f

# View tunnel logs
docker logs healthstack_tunnel_quick -f   # or healthstack_tunnel for named tunnel
```

---

## Container overview

| Container | Always on | Profile |
|---|---|---|
| `healthstack_postgres` | yes | — |
| `healthstack_redis` | yes | — |
| `healthstack_backend` | yes | — |
| `healthstack_nginx` | yes | — |
| `healthstack_tunnel_quick` | no | `quick` |
| `healthstack_tunnel` | no | `cloudflare` |
| `healthstack_nginx_ssl` | no | `domain` |
| `healthstack_certbot` | no | `domain` |

## Memory budget (Pi 3B, 1 GB RAM)

| Service | ~RAM |
|---|---|
| PostgreSQL | 150 MB |
| Redis | 50 MB |
| FastAPI | 150 MB |
| nginx | 10 MB |
| cloudflared | 30 MB |
| OS + overhead | 200 MB |
| **Total** | **~590 MB** |

1 GB swap configured by `01-system.sh` for safety headroom.
