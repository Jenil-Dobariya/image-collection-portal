#!/bin/bash

# SSL Setup Script for Smart Search and Rescue Project
# This script sets up SSL certificates using Let's Encrypt on Ubuntu server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

# Function to validate domain
validate_domain() {
    local domain=$1
    if [[ ! $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 1
    fi
    return 0
}

# Get domain name from user
echo "================================================"
echo "🔒 SSL Setup for Smart Search and Rescue Project"
echo "================================================"
echo ""

while true; do
    read -p "Enter your domain name (e.g., example.com): " DOMAIN
    if validate_domain "$DOMAIN"; then
        break
    else
        print_error "Invalid domain format. Please enter a valid domain name."
    fi
done

read -p "Enter your email address for Let's Encrypt notifications: " EMAIL

# Validate email
if [[ ! $EMAIL =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    print_error "Invalid email format"
    exit 1
fi

print_status "Domain: $DOMAIN"
print_status "Email: $EMAIL"
echo ""

read -p "Continue with SSL setup? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "SSL setup cancelled"
    exit 0
fi

print_status "Starting SSL setup process..."

# Update system packages
print_status "Updating system packages..."
apt update -qq

# Install required packages
print_status "Installing required packages..."
apt install -y snapd curl nginx-common

# Install certbot via snap (recommended method)
print_status "Installing Certbot..."
snap install core; snap refresh core
snap install --classic certbot

# Create symlink for certbot command
ln -sf /snap/bin/certbot /usr/bin/certbot

# Check if Docker and Docker Compose are installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create directories for Let's Encrypt
print_status "Creating directories for SSL certificates..."
mkdir -p /var/www/certbot
mkdir -p /etc/letsencrypt/live
mkdir -p /etc/letsencrypt/archive

# Stop any existing nginx service on the host
print_status "Stopping any existing nginx services..."
systemctl stop nginx 2>/dev/null || true
systemctl disable nginx 2>/dev/null || true

# Create temporary nginx configuration for certificate challenge
print_status "Creating temporary nginx configuration..."
cat > /tmp/nginx-temp.conf << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files \$uri =404;
    }
    
    location / {
        return 200 'SSL setup in progress...';
        add_header Content-Type text/plain;
    }
}
EOF

# Start temporary nginx container for certificate generation
print_status "Starting temporary nginx for certificate challenge..."
docker run -d --name nginx-temp \
    -p 80:80 \
    -v /tmp/nginx-temp.conf:/etc/nginx/conf.d/default.conf \
    -v /var/www/certbot:/var/www/certbot \
    nginx:alpine

# Wait for nginx to start
sleep 5

# Generate SSL certificate
print_status "Generating SSL certificate for $DOMAIN..."
certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --non-interactive \
    -d $DOMAIN \
    -d www.$DOMAIN

if [ $? -eq 0 ]; then
    print_success "SSL certificate generated successfully!"
else
    print_error "Failed to generate SSL certificate"
    docker rm -f nginx-temp 2>/dev/null || true
    exit 1
fi

# Stop temporary nginx
print_status "Stopping temporary nginx..."
docker rm -f nginx-temp 2>/dev/null || true

# Update nginx-ssl.conf with actual domain
print_status "Updating nginx configuration with your domain..."
if [ -f "nginx-ssl.conf" ]; then
    sed -i "s/yourdomain.com/$DOMAIN/g" nginx-ssl.conf
    print_success "Nginx configuration updated with domain $DOMAIN"
else
    print_warning "nginx-ssl.conf not found in current directory"
fi

# Create docker-compose.ssl.yml
print_status "Creating SSL-enabled docker-compose configuration..."
cat > docker-compose.ssl.yml << EOF
# SSL-enabled Docker Compose configuration
# Use this file for production deployment with SSL

services:
  nginx:
    image: nginx:alpine
    container_name: image-portal-nginx-ssl
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx-ssl.conf:/etc/nginx/conf.d/default.conf
      - /etc/letsencrypt:/etc/letsencrypt:ro
      - /var/www/certbot:/var/www/certbot:ro
      - upload_data:/app/data
    depends_on:
      - frontend
      - backend
    networks:
      - portal-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

  certbot:
    image: certbot/certbot
    container_name: image-portal-certbot
    volumes:
      - /etc/letsencrypt:/etc/letsencrypt
      - /var/www/certbot:/var/www/certbot
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait; done;'"
    restart: unless-stopped

networks:
  portal-network:
    driver: bridge

volumes:
  postgres_data:
  upload_data:
EOF

# Create certificate renewal script
print_status "Creating certificate renewal script..."
cat > /etc/cron.d/certbot-renew << EOF
# Renew Let's Encrypt certificates twice daily
0 12 * * * root /snap/bin/certbot renew --quiet --deploy-hook "docker exec image-portal-nginx-ssl nginx -s reload"
0 0 * * * root /snap/bin/certbot renew --quiet --deploy-hook "docker exec image-portal-nginx-ssl nginx -s reload"
EOF

# Set proper permissions
chmod 644 /etc/cron.d/certbot-renew

# Create deployment script
print_status "Creating SSL deployment script..."
cat > deploy-ssl.sh << 'EOF'
#!/bin/bash

# SSL Deployment Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if SSL certificates exist
if [ ! -f "/etc/letsencrypt/live/$(grep server_name nginx-ssl.conf | head -1 | awk '{print $2}' | tr -d ';')/fullchain.pem" ]; then
    print_error "SSL certificates not found. Run setup-ssl.sh first."
    exit 1
fi

print_status "Starting SSL deployment..."

# Stop any existing containers
print_status "Stopping existing containers..."
docker compose down 2>/dev/null || true

# Build and start with SSL configuration
print_status "Building and starting containers with SSL..."
docker compose -f docker-compose.yml -f docker-compose.prod.ssl.yml up -d --build

print_status "Waiting for services to start..."
sleep 30

# Health check
print_status "Performing health checks..."
if curl -f -s https://$(grep server_name nginx-ssl.conf | head -1 | awk '{print $2}' | tr -d ';')/health > /dev/null; then
    print_success "🎉 SSL deployment successful!"
    print_success "Your application is now available at:"
    echo "   📱 https://$(grep server_name nginx-ssl.conf | head -1 | awk '{print $2}' | tr -d ';')"
    echo ""
    print_status "Certificate auto-renewal is configured via cron job."
else
    print_error "Health check failed. Check logs with: docker compose logs"
fi
EOF

chmod +x deploy-ssl.sh

# Final instructions
echo ""
echo "================================================"
print_success "🎉 SSL Setup Complete!"
echo "================================================"
echo ""
print_status "Next steps:"
echo "1. Make sure your domain $DOMAIN points to this server's IP address"
echo "2. Update your .env file with production settings"
echo "3. Run: ./deploy-ssl.sh to start the application with SSL"
echo ""
print_status "Files created:"
echo "   📄 nginx-ssl.conf - SSL-enabled nginx configuration"
echo "   📄 docker-compose.ssl.yml - SSL docker compose configuration"
echo "   📄 deploy-ssl.sh - SSL deployment script"
echo ""
print_status "Certificate details:"
echo "   📁 Certificates: /etc/letsencrypt/live/$DOMAIN/"
echo "   🔄 Auto-renewal: Configured via cron (twice daily)"
echo ""
print_warning "Remember to:"
echo "   • Configure your domain DNS to point to this server"
echo "   • Update firewall rules to allow ports 80 and 443"
echo "   • Set NODE_ENV=production in your .env file"
echo ""
print_success "Your application will be available at: https://$DOMAIN"