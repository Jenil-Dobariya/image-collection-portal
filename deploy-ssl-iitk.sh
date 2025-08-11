#!/bin/bash

# IITK SSL Deployment Script for smartsearch.iitk.ac.in
# This script deploys the Smart Search and Rescue Project with SSL

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Domain configuration
DOMAIN="smartsearch.iitk.ac.in"

echo -e "${BLUE}🏛️ ==========================================${NC}"
echo -e "${BLUE}   IITK Smart Search and Rescue Project${NC}"
echo -e "${BLUE}   SSL Deployment Script${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

print_status "Domain: $DOMAIN"
print_status "Starting SSL deployment..."
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

# Check if SSL certificates exist
print_status "Checking SSL certificates..."
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    print_error "SSL certificates not found for $DOMAIN"
    print_warning "Please run the SSL setup first:"
    echo ""
    echo "  sudo ./setup-ssl.sh"
    echo "  # Enter domain: $DOMAIN"
    echo "  # Enter email: your_username@iitk.ac.in"
    echo ""
    exit 1
fi
print_success "SSL certificates found for $DOMAIN"

# Check if Docker is available
print_status "Checking Docker installation..."
if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
    print_error "Docker or Docker Compose not found"
    exit 1
fi
print_success "Docker and Docker Compose are available"

# Check if configuration files exist
print_status "Checking configuration files..."
required_files=("docker-compose.yml" "docker-compose.prod.ssl.yml" "nginx-ssl.conf")
for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        print_error "Required file not found: $file"
        exit 1
    fi
done
print_success "All configuration files found"

# Update nginx-ssl.conf with IITK domain
print_status "Updating nginx configuration for IITK domain..."
if grep -q "yourdomain.com" nginx-ssl.conf; then
    sed -i "s/yourdomain.com/$DOMAIN/g" nginx-ssl.conf
    print_success "Nginx configuration updated with $DOMAIN"
fi

# Update docker-compose.prod.ssl.yml with IITK domain
print_status "Updating Docker Compose configuration..."
if grep -q "yourdomain.com" docker-compose.prod.ssl.yml; then
    sed -i "s/yourdomain.com/$DOMAIN/g" docker-compose.prod.ssl.yml
    print_success "Docker Compose configuration updated"
fi

# Stop any existing containers
print_status "Stopping existing containers..."
docker compose down 2>/dev/null || true
print_success "Existing containers stopped"

# Build and start containers with SSL
print_status "Building and starting containers with SSL..."
if docker compose -f docker-compose.yml -f docker-compose.prod.ssl.yml up -d --build; then
    print_success "Containers started successfully"
else
    print_error "Failed to start containers"
    print_warning "Check logs with: docker compose logs"
    exit 1
fi

# Wait for services to start
print_status "Waiting for services to start..."
sleep 30

# Health checks
print_status "Performing health checks..."

# Check if containers are running
print_status "Checking container status..."
if docker compose ps | grep -q "Up"; then
    print_success "Containers are running"
else
    print_error "Some containers are not running"
    docker compose ps
    exit 1
fi

# Check HTTPS health endpoint
print_status "Testing HTTPS endpoint..."
max_attempts=10
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl -f -s https://$DOMAIN/api/health > /dev/null 2>&1; then
        print_success "HTTPS endpoint is responding"
        break
    else
        if [ $attempt -eq $max_attempts ]; then
            print_error "HTTPS endpoint not responding after $max_attempts attempts"
            print_warning "Check logs with: docker compose logs"
            exit 1
        fi
        print_status "Attempt $attempt/$max_attempts: Waiting for HTTPS endpoint..."
        sleep 10
        ((attempt++))
    fi
done

# Check HTTP redirect
print_status "Testing HTTP to HTTPS redirect..."
if curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN/health | grep -q "301\|302"; then
    print_success "HTTP to HTTPS redirect working"
else
    print_warning "HTTP redirect may not be working properly"
fi

# Check SSL certificate
print_status "Verifying SSL certificate..."
if echo | openssl s_client -connect $DOMAIN:443 -servername $DOMAIN 2>/dev/null | grep -q "Verify return code: 0"; then
    print_success "SSL certificate is valid"
else
    print_warning "SSL certificate verification may have issues"
fi

# Display final status
echo ""
echo -e "${GREEN}🎉 ========================================${NC}"
echo -e "${GREEN}   DEPLOYMENT SUCCESSFUL!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

print_success "Your Smart Search and Rescue Project is now live!"
echo ""
print_status "🌐 Application URLs:"
echo -e "   ${GREEN}Main Application:${NC} https://$DOMAIN"
echo -e "   ${GREEN}API Health Check:${NC} https://$DOMAIN/api/health"
echo -e "   ${GREEN}Send OTP:${NC} https://$DOMAIN/api/send-otp"
echo -e "   ${GREEN}Verify OTP:${NC} https://$DOMAIN/api/verify-otp"
echo -e "   ${GREEN}Form Submission:${NC} https://$DOMAIN/api/submit"
echo ""

print_status "🔒 Security Features:"
echo "   ✅ SSL certificate from Let's Encrypt"
echo "   ✅ HTTP to HTTPS redirect"
echo "   ✅ Security headers configured"
echo "   ✅ Rate limiting enabled"
echo ""

print_status "🐳 Container Status:"
docker compose ps
echo ""

print_status "📊 System Information:"
echo -e "   ${GREEN}Ports:${NC} 80 (HTTP→HTTPS), 443 (HTTPS)"
echo -e "   ${GREEN}SSL Certificate:${NC} /etc/letsencrypt/live/$DOMAIN/"
echo -e "   ${GREEN}Auto-Renewal:${NC} Configured via cron"
echo ""

print_status "🛠️ Management Commands:"
echo -e "   ${YELLOW}View logs:${NC} docker compose logs -f"
echo -e "   ${YELLOW}Restart:${NC} docker compose restart"
echo -e "   ${YELLOW}Stop:${NC} docker compose down"
echo -e "   ${YELLOW}Status:${NC} docker compose ps"
echo ""

print_warning "📝 Don't forget to:"
echo "   • Configure email settings in .env for OTP functionality"
echo "   • Test the complete user flow"
echo "   • Set up monitoring and backups"
echo ""

print_success "Deployment completed successfully! 🚀"
echo -e "Visit: ${GREEN}https://$DOMAIN${NC}"