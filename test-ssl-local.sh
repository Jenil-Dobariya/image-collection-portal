#!/bin/bash

# Local SSL Testing Script
# Test SSL configuration with self-signed certificates for development

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Create local SSL testing environment
create_test_ssl_certs() {
    print_status "Creating self-signed certificates for local testing..."
    
    # Create SSL directory
    mkdir -p ./test-ssl/certs
    
    # Generate private key
    openssl genrsa -out ./test-ssl/certs/privkey.pem 2048
    
    # Generate certificate
    openssl req -new -x509 -key ./test-ssl/certs/privkey.pem \
        -out ./test-ssl/certs/fullchain.pem -days 365 \
        -subj "/C=US/ST=Test/L=Test/O=TestOrg/CN=localhost"
    
    print_success "Self-signed certificates created"
}

# Create test nginx configuration
create_test_nginx_config() {
    print_status "Creating test nginx configuration..."
    
    mkdir -p ./test-ssl
    
    cat > ./test-ssl/nginx-test.conf << 'EOF'
# Test nginx configuration with self-signed certificates
server {
    listen 80;
    server_name localhost;
    
    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name localhost;
    
    # Self-signed certificates for testing
    ssl_certificate /etc/ssl/certs/fullchain.pem;
    ssl_certificate_key /etc/ssl/certs/privkey.pem;
    
    # Basic SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    
    # Test endpoints
    location /health {
        return 200 "SSL Test OK\n";
        add_header Content-Type text/plain;
    }
    
    location /api/ {
        proxy_pass http://host.docker.internal:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location / {
        proxy_pass http://host.docker.internal:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
    
    print_success "Test nginx configuration created"
}

# Create test docker-compose
create_test_compose() {
    print_status "Creating test docker-compose for SSL..."
    
    cat > ./test-ssl/docker-compose.test-ssl.yml << 'EOF'
# Test SSL configuration
services:
  nginx-ssl-test:
    image: nginx:alpine
    container_name: test-ssl-nginx
    ports:
      - "8080:80"   # HTTP redirect test
      - "8443:443"  # HTTPS test
    volumes:
      - ./nginx-test.conf:/etc/nginx/conf.d/default.conf:ro
      - ./certs:/etc/ssl/certs:ro
    restart: unless-stopped
    networks:
      - test-network

networks:
  test-network:
    driver: bridge
EOF
    
    print_success "Test docker-compose created"
}

# Test SSL configuration syntax
test_ssl_syntax() {
    print_status "Testing SSL configuration syntax..."
    
    # Test nginx config syntax
    if docker run --rm \
        -v "$(pwd)/test-ssl/nginx-test.conf:/etc/nginx/conf.d/default.conf:ro" \
        -v "$(pwd)/test-ssl/certs:/etc/ssl/certs:ro" \
        nginx:alpine nginx -t 2>/dev/null; then
        print_success "✓ SSL nginx configuration syntax is valid"
    else
        print_error "✗ SSL nginx configuration has syntax errors"
        return 1
    fi
}

# Start test SSL server
start_test_ssl_server() {
    print_status "Starting test SSL server..."
    
    cd test-ssl
    docker compose -f docker-compose.test-ssl.yml up -d
    cd ..
    
    # Wait for server to start
    sleep 5
    
    print_success "Test SSL server started on ports 8080 (HTTP) and 8443 (HTTPS)"
}

# Test SSL endpoints
test_ssl_endpoints() {
    print_status "Testing SSL endpoints..."
    
    # Test HTTP redirect
    print_status "Testing HTTP redirect..."
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health | grep -q "301"; then
        print_success "✓ HTTP redirect working"
    else
        print_warning "⚠ HTTP redirect not working"
    fi
    
    # Test HTTPS endpoint (ignore certificate errors for self-signed)
    print_status "Testing HTTPS endpoint..."
    if curl -k -s https://localhost:8443/health | grep -q "SSL Test OK"; then
        print_success "✓ HTTPS endpoint working"
    else
        print_warning "⚠ HTTPS endpoint not working"
    fi
    
    # Test SSL certificate
    print_status "Testing SSL certificate..."
    if openssl s_client -connect localhost:8443 -servername localhost < /dev/null 2>/dev/null | grep -q "Verify return code: 18"; then
        print_success "✓ SSL certificate loaded (self-signed as expected)"
    else
        print_warning "⚠ SSL certificate verification issues"
    fi
}

# Cleanup test environment
cleanup_test() {
    print_status "Cleaning up test environment..."
    
    if [ -d "./test-ssl" ]; then
        cd test-ssl
        docker compose -f docker-compose.test-ssl.yml down 2>/dev/null || true
        cd ..
        rm -rf test-ssl
    fi
    
    print_success "Test environment cleaned up"
}

# Validate real SSL scripts
validate_real_ssl_scripts() {
    print_status "Validating real SSL scripts..."
    
    # Check setup-ssl.sh
    if [[ -f "setup-ssl.sh" ]]; then
        print_status "Checking setup-ssl.sh..."
        
        # Test script syntax
        if bash -n setup-ssl.sh; then
            print_success "✓ setup-ssl.sh syntax is valid"
        else
            print_error "✗ setup-ssl.sh has syntax errors"
        fi
        
        # Check for required functions
        if grep -q "validate_domain" setup-ssl.sh; then
            print_success "✓ Domain validation function present"
        fi
        
        if grep -q "certbot certonly" setup-ssl.sh; then
            print_success "✓ Certbot certificate generation present"
        fi
        
        if grep -q "docker compose" setup-ssl.sh; then
            print_success "✓ Uses modern Docker Compose syntax"
        fi
    fi
    
    # Check quick-ssl-setup.sh
    if [[ -f "quick-ssl-setup.sh" ]]; then
        print_status "Checking quick-ssl-setup.sh..."
        
        if bash -n quick-ssl-setup.sh; then
            print_success "✓ quick-ssl-setup.sh syntax is valid"
        else
            print_error "✗ quick-ssl-setup.sh has syntax errors"
        fi
    fi
    
    # Check docker-compose.prod.ssl.yml
    if [[ -f "docker-compose.prod.ssl.yml" ]]; then
        print_status "Checking docker-compose.prod.ssl.yml..."
        
        if docker compose -f docker-compose.yml -f docker-compose.prod.ssl.yml config > /dev/null 2>&1; then
            print_success "✓ SSL docker-compose configuration is valid"
        else
            print_error "✗ SSL docker-compose configuration has issues"
        fi
    fi
    
    # Check nginx-ssl.conf
    if [[ -f "nginx-ssl.conf" ]]; then
        print_status "Checking nginx-ssl.conf..."
        
        if grep -q "ssl_certificate" nginx-ssl.conf && grep -q "ssl_certificate_key" nginx-ssl.conf; then
            print_success "✓ SSL certificate directives present"
        fi
        
        if grep -q "listen 443 ssl" nginx-ssl.conf; then
            print_success "✓ HTTPS listener configured"
        fi
        
        if grep -q "return 301 https" nginx-ssl.conf; then
            print_success "✓ HTTP to HTTPS redirect configured"
        fi
    fi
}

# Main function
main() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}  Local SSL Testing Suite${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
    
    # Validate scripts first
    validate_real_ssl_scripts
    echo ""
    
    # Ask user if they want to run full test
    read -p "Run full SSL test with local certificates? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Setting up local SSL test environment..."
        
        # Setup test environment
        create_test_ssl_certs
        create_test_nginx_config
        create_test_compose
        
        # Test configuration
        test_ssl_syntax
        
        if [ $? -eq 0 ]; then
            # Start test server
            start_test_ssl_server
            
            # Test endpoints
            test_ssl_endpoints
            
            echo ""
            print_success "🎉 Local SSL test completed!"
            echo ""
            print_status "Test results:"
            echo "• HTTP redirect: http://localhost:8080 → https://localhost:8443"
            echo "• HTTPS endpoint: https://localhost:8443 (self-signed certificate)"
            echo "• Configuration syntax: Validated"
            echo ""
            print_warning "Note: Browser will show security warning due to self-signed certificate"
            echo ""
            
            read -p "Press Enter to cleanup test environment..." -r
            cleanup_test
        else
            print_error "SSL configuration test failed"
            cleanup_test
            exit 1
        fi
    else
        print_status "Skipping full SSL test"
    fi
    
    echo ""
    print_success "✅ SSL scripts validation completed!"
    echo ""
    print_status "Your SSL scripts are ready for deployment on Ubuntu server"
    print_warning "Remember: Real deployment requires actual domain and Let's Encrypt certificates"
}

# Handle cleanup on script exit
trap cleanup_test EXIT

# Run main function
main "$@"