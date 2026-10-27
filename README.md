# Pi-hole + Unbound DNS over TLS Setup

> A Docker Compose setup for network-wide DNS filtering with encrypted upstream DNS-over-TLS (DoT) forwarding.

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Docker Compose](https://img.shields.io/badge/Docker%20Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![Pi-hole](https://img.shields.io/badge/Pi--hole-96060C?style=for-the-badge&logo=pihole&logoColor=white)](https://pi-hole.net/)
[![Unbound](https://img.shields.io/badge/Unbound-1E90FF?style=for-the-badge&logo=unbound&logoColor=white)](https://www.nlnetlabs.nl/projects/unbound/about/)
[![Caddy](https://img.shields.io/badge/Caddy-0E7CBE?style=for-the-badge&logo=caddy&logoColor=white)](https://caddyserver.com/)
[![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.linux.org/)

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Services](#services)
- [Directory Structure](#directory-structure)
- [Troubleshooting](#troubleshooting)

## Overview

A production-ready DNS infrastructure stack deployed on **Raspberry Pi** with secure HTTPS access. This project combines:

- **Pi-hole**: Network-wide ad blocker and DNS management
- **Unbound**: Local DNS forwarder that sends upstream queries over DNS-over-TLS
- **Caddy**: Reverse proxy providing secure HTTPS access to admin dashboard at `homelab.local`

The stack runs Pi-hole and Unbound in one custom container. Pi-hole accepts DNS requests from your network on port 53, then Unbound forwards them to Cloudflare and Quad9 over TLS on port 853. This can avoid ISP interception of ordinary outbound DNS on port 53; it is encrypted forwarding, not root-server recursion.

## Features

- **Encrypted Upstream DNS**: Unbound forwards queries to Cloudflare and Quad9 over TLS (port 853)
- **Ad Blocking**: Network-wide ad and tracker blocking with Pi-hole
- **Web Dashboard**: Pi-hole admin interface on port 8080
- **HTTPS Support**: Caddy reverse proxy with automatic HTTPS
- **Containerized**: Complete Docker Compose stack
- **Auto-restart**: Services automatically restart on failure
- **Configurable Timezone**: Set to any timezone (default: Asia/Dhaka)

## Architecture

```bash
┌─────────────────────────────────────────────────────────┐
│                    DNS Clients                          │
│                 (Port 53 TCP/UDP)                       │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│              Pi-hole (DNS Sinkhole)                     │
│  - Ad & Tracker Blocking                                │
│  - Upstream: Unbound at 127.0.0.1#5335                 │
│  - Admin Dashboard: https://homelab.local               │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  Pi-hole + Unbound (one container)                      │
│  - Local Unbound listener: 127.0.0.1:5335              │
│  - DoT upstreams: Cloudflare and Quad9, port 853        │
│  - Custom configuration                                 │
└──────────────┬──────────────────────────────────────────┘
               │
  ┌──────▼──────────────────────┐
  │ Cloudflare / Quad9 over DoT  │
  │          TCP 853            │
  └─────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│           Caddy (Reverse Proxy)                          │
│  - HTTPS/HTTP Proxy                                      │
│  - Port 80, 443                                          │
└──────────────────────────────────────────────────────────┘
```

## Prerequisites

- **Raspberry Pi 3B+** or higher (2GB+ RAM recommended)
- Docker Engine 20.10+ (with Docker Compose v2.0+)
- 2GB disk space minimum
- Network connectivity for DNS queries
- Ability to add DNS server to network devices

## Installation

### Prerequisites on Raspberry Pi

1. **Install Docker & Docker Compose**:

```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker $USER
   newgrp docker

  sudo apt-get install -y docker-compose-plugin

```

2. **Verify Installation**:

```bash
   docker --version
  docker compose version

 ```

### 1. Clone or Download the Repository

```bash
git clone https://github.com/ks-arafat/PiHole-Unbound.git
cd PiHole-Unbound
```

### 2. Create Required Directories

```bash
mkdir -p pihole/etc-pihole pihole/etc-dnsmasq.d logs
```

### 3. Configure Timezone (Optional)

Edit `docker-compose.yml` and update the timezone:

```bash
sed -i 's/Asia\\/Dhaka/Your\\/Timezone/g' docker-compose.yml
```

### 4. Start Services

```bash
docker compose up -d --build
```

The `--build` option builds the combined Pi-hole/Unbound image from the repository's `Dockerfile`. Unbound forwards DNS over TLS to Cloudflare and Quad9; it does not perform root-server recursion. The network-facing DNS service still listens on port 53, while encrypted upstream connections use port 853. Ensure your network allows outbound TCP port 853.

### 5. Verify Services

```bash
docker compose ps
```

Expected output:

```bash
NAME       STATUS    PORTS
pibound    Up        0.0.0.0:53->53/tcp, 0.0.0.0:53->53/udp, 0.0.0.0:8080->80/tcp
caddy-pb   Up        0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
```

### 6. Access the Dashboard

Find your Raspberry Pi's IP:

```bash
hostname -I
```

Access Pi-hole admin from any device on your network:

```url
https://homelab.local/admin
```

If `homelab.local` doesn't resolve, use the direct IP:

```url
https://<raspberry-pi-ip>
```

## Configuration

### Pi-hole Configuration

Access the Pi-hole admin dashboard via **HTTPS**:

```url
https://homelab.local/admin
```

**Note**: The Caddy reverse proxy provides secure HTTPS access with internal TLS certificates. Your browser may show a certificate warning—this is normal for self-signed certs. You can safely proceed.

**First-time setup:**

- Navigate to `https://homelab.local/admin`
- Set your admin password on first login
- Username: `admin`

**Key Settings:**

- Set Pi-hole as your network's DNS server
- Leave Pi-hole's upstream DNS setting at `127.0.0.1#5335`; this is set by Compose
- Unbound's configured DoT upstreams are Cloudflare and Quad9
- Configure blocklists as needed

### Unbound Configuration

Edit `unbound/unbound-pihole.conf` to customize Unbound. The current configuration listens only inside the container and forwards all queries over TLS:

```ini
server:
    interface: 127.0.0.1
    port: 5335
    hide-identity: yes
    hide-version: yes
    tls-cert-bundle: "/etc/ssl/certs/ca-certificates.crt"

forward-zone:
    name: "."
    forward-tls-upstream: yes
    forward-addr: 1.1.1.1@853#cloudflare-dns.com
    forward-addr: 1.0.0.1@853#cloudflare-dns.com
    forward-addr: 9.9.9.9@853#dns.quad9.net
    forward-addr: 149.112.112.112@853#dns.quad9.net
```

Rebuild and restart the `pihole` service after changing this file: `docker compose up -d --build pihole`.

### Timezone Configuration

Edit `docker-compose.yml` and update the `TZ` environment variable:

```yaml
environment:
  TZ: "America/New_York"  # Change to your timezone
```

Use [IANA Timezone Database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) format.

### Caddy Configuration

The `Caddyfile` is pre-configured to provide HTTPS access to Pi-hole:

```caddy
homelab.local {
    tls internal
    reverse_proxy pihole:80
    redir / /admin/
}
```

**What this does:**

- Creates HTTPS endpoint at `https://homelab.local`
- Uses internal TLS certificates (no manual cert management)
- Proxies traffic to Pi-hole web interface
- Automatically redirects root path to `/admin/`

To use a custom domain, edit `homelab.local` to your domain name in the `Caddyfile`.

## Usage

### Basic Operations

**View logs:**

```bash
docker compose logs -f pihole
docker compose logs -f caddy
```

**Restart services:**

```bash
docker compose restart pihole
```

**Stop all services:**

```bash
docker compose down
```

**Update images:**

```bash
docker compose pull
docker compose up -d --build
```

### DNS Configuration on Clients

Point your DNS queries to your Raspberry Pi's IP address (replace `<raspberry-pi-ip>` with actual IP):

**Router (Recommended):**

1. Access your router admin panel (usually 192.168.1.1 or 192.168.0.1)
2. Find DNS settings (may be under DHCP or WAN settings)
3. Set primary DNS to `<raspberry-pi-ip>`
4. Save and restart router
5. All connected devices will now use Pi-hole DNS

**Linux:**

```bash
# Using nmcli (NetworkManager)
nmcli con mod <connection-name> ipv4.dns "<raspberry-pi-ip>"
nmcli con up <connection-name>
```

**macOS:**

```bash
# System Settings > Network > WiFi/Ethernet > DNS Servers
# Add: <raspberry-pi-ip>
```

**Windows:**

```cmd
Settings > Network & Internet > Change adapter options > 
Double-click your connection > Properties > Internet Protocol Version 4 > 
Properties > Use the following DNS server addresses:
  Preferred: <raspberry-pi-ip>
```

**Access Admin Dashboard:**

- From any device on your network: `https://homelab.local/admin`
- You may need to add `homelab.local` to your `/etc/hosts` file:

  ```bash
  echo "<raspberry-pi-ip>  homelab.local" | sudo tee -a /etc/hosts
  ```

## Services

### Pi-hole + Unbound

- **Image**: Built locally from `Dockerfile`, based on `pihole/pihole:latest`
- **Container**: `pibound` (Compose service: `pihole`)
- **DNS for clients**: Port 53 TCP/UDP
- **Pi-hole upstream**: Unbound at `127.0.0.1#5335`
- **DoT upstreams**: Cloudflare and Quad9 on TCP port 853
- **Unbound config**: `unbound/unbound-pihole.conf`
- **Startup**: `entrypoint.sh` starts Unbound and Pi-hole in the same container

### Pi-hole

- **Image**: `pihole/pihole:latest`
- **DNS Port**: 53 (TCP/UDP)
- **Admin Dashboard**: Via Caddy HTTPS at `https://homelab.local/admin`
- **Internal Port**: 8080 (proxied through Caddy)
- **Upstream**: Unbound in the same container (port 5335)
- **Features**: Ad blocking, DNS management, query logs

### Caddy

- **Image**: `caddy:latest`
- **HTTP Port**: 80
- **HTTPS Port**: 443
- **Features**: Reverse proxy, internal TLS certificates, zero-config setup
- **Purpose**: Provides secure HTTPS access to Pi-hole admin dashboard

## Directory Structure

```bash
.
├── Caddyfile              # Caddy reverse proxy configuration
├── docker-compose.yml     # Pi-hole/Unbound and Caddy services
├── Dockerfile             # Builds the combined Pi-hole + Unbound image
├── entrypoint.sh          # Starts both processes in the combined container
├── README.md              # This file
├── unbound/
│   ├── unbound-pihole.conf # Unbound DoT forwarding configuration
│   ├── root.hints         # Root hints bundled at image build time
│   └── roothints.sh       # Root hints download script
├── pihole/
│   ├── etc-pihole/        # Pi-hole configuration directory
│   └── etc-dnsmasq.d/     # Dnsmasq configuration directory
└── logs/                  # Unbound logs directory
```

## Troubleshooting

### Pi-hole won't start

```bash
docker compose logs pihole
# Check if port 53 is already in use
sudo lsof -i :53
```

### DNS not resolving

1. Check both processes' container logs: `docker compose logs pihole`
2. Verify Pi-hole's upstream is `127.0.0.1#5335`
3. Check that outbound TCP port 853 is allowed by your router/firewall
4. Confirm clients can reach the Pi-hole host on TCP and UDP port 53

### DoT upstream not resolving

```bash
# Check the merged service logs
docker compose logs --tail=100 pihole
# Check whether the host can reach a DoT upstream
nc -vz 1.1.1.1 853
```

If outbound port 853 is blocked, Unbound cannot reach its configured encrypted upstreams. The `root.hints` file does not provide fallback recursion in this forwarding configuration.

### High CPU/Memory usage

- Reduce log verbosity in `unbound/unbound-pihole.conf`
- Check Pi-hole query logs for unusual traffic
- Verify blocklists aren't too large

### Cannot access Pi-hole admin dashboard

**Find Raspberry Pi IP address:**

```bash
hostname -I
# Or from another device, check your router's connected devices list
```

**Cannot access homelab.local:**

1. Ensure Caddy container is running: `docker compose ps caddy`
2. Add entry to your hosts file:

   ```bash
   sudo nano /etc/hosts
   # Add: <raspberry-pi-ip>  homelab.local
   ```

3. Try direct IP access (with port): `https://<raspberry-pi-ip>`

**Reset Pi-hole admin password:**

```bash
# SSH into Raspberry Pi
ssh user@<raspberry-pi-ip>
cd /path/to/PiHole-Unbound
docker exec pihole pihole -a -p
```

## Resources

- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [Unbound Manual](https://www.nlnetlabs.nl/projects/unbound/unbound-manual/)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [IANA Timezone Database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

## License

This project is provided as-is for personal and educational use.

## Contributing

Feel free to submit issues and enhancement requests!

---

**Last Updated**: 2026-10-27
**Tested On**: Raspberry Pi (Raspbian/Debian based systems)  
**Deployment Model**: Docker Compose with HTTPS dashboard via Caddy
