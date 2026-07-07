# Pi-hole + Unbound DNS Setup

> A complete Docker Compose setup for a high-performance DNS server with ad-blocking and recursive resolution capabilities.

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
- **Unbound**: Recursive, validating DNS resolver with DNSSEC support
- **Caddy**: Reverse proxy providing secure HTTPS access to admin dashboard at `homelab.local`

Perfect for home networks requiring robust DNS filtering, privacy-focused recursive resolution, and secure remote administration.

## Features

- **Fast DNS Resolution**: Recursive resolution with Unbound
- **Ad Blocking**: Network-wide ad and tracker blocking with Pi-hole
- **DNSSEC Validation**: Secure DNS with DNSSEC enabled
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
│  - Upstream: Unbound#53                                 │
│  - Admin Dashboard: https://homelab.local               │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│          Unbound (Recursive Resolver)                   │
│  - DNSSEC Validation                                    │
│  - Root Hints (Updated)                                 │
│  - Custom Configuration                                 │
└──────────────┬──────────────────────────────────────────┘
               │
        ┌──────▼────────┐
        │ Authoritative │
        │   DNS Roots   │
        └───────────────┘

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
   
   sudo apt-get install -y docker-compose
   ```

2. **Verify Installation**:

   ```bash
   docker --version
   docker-compose --version
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
docker-compose up -d
```

**Note:** Ensure the `unbound/root.hints` file exists. If it doesn't, download it using:

```bash
cd unbound
bash roothints.sh
cd ..
```

### 5. Verify Services

```bash
docker-compose ps
```

Expected output:

```bash
NAME               STATUS    PORTS
unbound            Up        53/tcp, 53/udp
pihole             Up        53/tcp, 53/udp, 0.0.0.0:8080->80/tcp
caddy              Up        0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
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
- Configure upstream DNS (already set to Unbound)
- Enable DNSSEC validation
- Configure blocklists as needed

### Unbound Configuration

Edit `unbound/unbound.conf` to customize DNS behavior:

```ini
# Key settings in unbound.conf
server:
    # Port for DNS queries
    port: 53
    
    # Interface to listen on
    interface: 0.0.0.0
    
    # DNSSEC validation
    dnssec: yes
    
    # Hide server info
    hide-identity: yes
    hide-version: yes
```

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
docker-compose logs -f pihole
docker-compose logs -f unbound
docker-compose logs -f caddy
```

**Restart services:**

```bash
docker-compose restart pihole
docker-compose restart unbound
```

**Stop all services:**

```bash
docker-compose down
```

**Update images:**

```bash
docker-compose pull
docker-compose up -d
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

### Unbound

- **Image**: `klutchell/unbound:latest`
- **Port**: 53 (TCP/UDP)
- **Features**: Recursive DNS, DNSSEC validation, root hints
- **Config**: `unbound/unbound.conf`
- **Root Hints**: `unbound/root.hints` (download using `roothints.sh`)
- **Logging**: persisted to `./logs`

### Pi-hole

- **Image**: `pihole/pihole:latest`
- **DNS Port**: 53 (TCP/UDP)
- **Admin Dashboard**: Via Caddy HTTPS at `https://homelab.local/admin`
- **Internal Port**: 8080 (proxied through Caddy)
- **Upstream**: Unbound (port 53)
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
├── docker-compose.yml     # Docker Compose services definition
├── README.md              # This file
├── unbound/
│   ├── unbound.conf       # Unbound DNS resolver configuration
│   ├── root.hints         # Root DNS hints file
│   └── roothints.sh       # Script to update root hints
├── pihole/
│   ├── etc-pihole/        # Pi-hole configuration directory
│   └── etc-dnsmasq.d/     # Dnsmasq configuration directory
└── logs/                  # Unbound logs directory
```

## Troubleshooting

### Pi-hole won't start

```bash
docker-compose logs pihole
# Check if port 53 is already in use
sudo lsof -i :53
```

### DNS not resolving

1. Verify Unbound is running: `docker-compose ps unbound`
2. Check logs: `docker-compose logs unbound`
3. Verify Pi-hole upstream DNS setting points to unbound:53
4. Check firewall rules allow port 53

### Unbound DNSSEC failures

```bash
# Remove the old root.hints and restart Unbound
rm unbound/root.hints
docker-compose restart unbound
```

### High CPU/Memory usage

- Reduce log verbosity in `unbound.conf`
- Check Pi-hole query logs for unusual traffic
- Verify blocklists aren't too large

### Cannot access Pi-hole admin dashboard

**Find Raspberry Pi IP address:**

```bash
hostname -I
# Or from another device, check your router's connected devices list
```

**Cannot access homelab.local:**

1. Ensure Caddy container is running: `docker-compose ps caddy`
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

**Last Updated**: 2026-07-07  
**Tested On**: Raspberry Pi (Raspbian/Debian based systems)  
**Deployment Model**: Docker Compose with HTTPS dashboard via Caddy
