#!/bin/bash

# Quick SSL Setup Script for Ubuntu Server
# One-command deployment with SSL

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Smart Search and Rescue Project - Quick SSL Setup${NC}"
echo "=================================================================="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Get parameters
DOMAIN=${1:-}
EMAIL=${2:-}

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "Usage: sudo $0 <domain> <email>"
    echo "Example: sudo $0 example.com admin@example.com"
    exit 1
fi

echo -e "${BLUE}Setting up SSL for:${NC}"
echo "Domain: $DOMAIN"
echo "Email: $EMAIL"
echo ""

# Install dependencies
echo -e "${BLUE}📦 Installing dependencies...${NC}"
apt update -qq
apt install -y snapd curl git

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo -e "${BLUE}🐳 Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    apt install -y docker-compose-plugin
fi

# Install Certbot
echo -e "${BLUE}🔒 Installing Certbot...${NC}"
snap install core; snap refresh core
snap install --classic certbot
ln -sf /snap/bin/certbot /usr/bin/certbot

# Setup directories
mkdir -p /var/www/certbot

# Stop any conflicting services
systemctl stop nginx 2>/dev/null || true
systemctl disable nginx 2>/dev/null || true

# Create minimal nginx for challenge
echo -e "${BLUE}🔧 Setting up certificate challenge...${NC}"
docker run -d --name nginx-temp \
    -p 80:80 \
    -v /var/www/certbot:/var/www/certbot \
    -v /tmp/nginx-temp.conf:/etc/nginx/conf.d/default.conf \
    nginx:alpine || true

cat > /tmp/nginx-temp.conf << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    location / {
        return 200 'SSL setup in progress...';
        add_header Content-Type text/plain;
    }
}
EOF

# Restart nginx-temp with new config
docker restart nginx-temp 2>/dev/null || docker run -d --name nginx-temp \
    -p 80:80 \
    -v /var/www/certbot:/var/www/certbot \
    -v /tmp/nginx-temp.conf:/etc/nginx/conf.d/default.conf \
    nginx:alpine

sleep 5

# Generate certificate
echo -e "${BLUE}🎫 Generating SSL certificate...${NC}"
certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --non-interactive \
    -d $DOMAIN \
    -d www.$DOMAIN

# Cleanup
docker rm -f nginx-temp

# Setup cron for renewal
cat > /etc/cron.d/certbot-renew << EOF
0 12 * * * root /snap/bin/certbot renew --quiet
0 0 * * * root /snap/bin/certbot renew --quiet
EOF

echo -e "${GREEN}✅ SSL certificate generated successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo "1. Upload your project files to this server"
echo "2. Update nginx-ssl.conf with your domain"
echo "3. Run: docker-compose -f docker-compose.yml -f docker-compose.prod.ssl.yml up -d"
echo ""
echo -e "${GREEN}🎉 Your SSL certificates are ready!${NC}"
echo "Certificates: /etc/letsencrypt/live/$DOMAIN/"