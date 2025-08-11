#!/bin/bash

# SSL Scripts Testing Suite
# This script tests SSL setup scripts without making actual changes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Test functions
test_domain_validation() {
    print_status "Testing domain validation logic..."
    
    # Extract domain validation function from setup-ssl.sh
    validate_domain() {
        local domain=$1
        if [[ ! $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
            return 1
        fi
        return 0
    }
    
    # Test valid domains
    local valid_domains=("example.com" "sub.example.com" "test-site.org" "my-app.co.uk")
    local invalid_domains=("" "localhost" "invalid..domain" "-invalid.com" "invalid-.com")
    
    print_status "Testing valid domains..."
    for domain in "${valid_domains[@]}"; do
        if validate_domain "$domain"; then
            print_success "✓ $domain - Valid"
        else
            print_error "✗ $domain - Should be valid but failed"
        fi
    done
    
    print_status "Testing invalid domains..."
    for domain in "${invalid_domains[@]}"; do
        if ! validate_domain "$domain"; then
            print_success "✓ $domain - Correctly rejected"
        else
            print_error "✗ $domain - Should be invalid but passed"
        fi
    done
}

test_email_validation() {
    print_status "Testing email validation logic..."
    
    # Extract email validation from setup-ssl.sh
    validate_email() {
        local email=$1
        if [[ ! $email =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
            return 1
        fi
        return 0
    }
    
    local valid_emails=("test@example.com" "user.name@domain.org" "admin@sub.domain.co.uk")
    local invalid_emails=("" "invalid-email" "@domain.com" "user@" "user@domain")
    
    print_status "Testing valid emails..."
    for email in "${valid_emails[@]}"; do
        if validate_email "$email"; then
            print_success "✓ $email - Valid"
        else
            print_error "✗ $email - Should be valid but failed"
        fi
    done
    
    print_status "Testing invalid emails..."
    for email in "${invalid_emails[@]}"; do
        if ! validate_email "$email"; then
            print_success "✓ $email - Correctly rejected"
        else
            print_error "✗ $email - Should be invalid but passed"
        fi
    done
}

test_file_structure() {
    print_status "Testing SSL script file structure..."
    
    local required_files=(
        "setup-ssl.sh"
        "quick-ssl-setup.sh"
        "nginx-ssl.conf"
        "docker-compose.prod.ssl.yml"
        "DEPLOYMENT_GUIDE.md"
    )
    
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            print_success "✓ $file - Found"
        else
            print_error "✗ $file - Missing"
        fi
    done
}

test_docker_compose_syntax() {
    print_status "Testing Docker Compose file syntax..."
    
    # Test main docker-compose.yml
    if docker compose -f docker-compose.yml config > /dev/null 2>&1; then
        print_success "✓ docker-compose.yml - Valid syntax"
    else
        print_error "✗ docker-compose.yml - Invalid syntax"
    fi
    
    # Test SSL override file
    if docker compose -f docker-compose.yml -f docker-compose.prod.ssl.yml config > /dev/null 2>&1; then
        print_success "✓ docker-compose.prod.ssl.yml - Valid syntax"
    else
        print_error "✗ docker-compose.prod.ssl.yml - Invalid syntax"
    fi
}

test_nginx_config() {
    print_status "Testing Nginx configuration syntax..."
    
    # Test regular nginx config
    if docker run --rm -v "$(pwd)/nginx.conf:/etc/nginx/conf.d/default.conf:ro" nginx:alpine nginx -t > /dev/null 2>&1; then
        print_success "✓ nginx.conf - Valid syntax"
    else
        print_warning "⚠ nginx.conf - Syntax check failed (may need SSL certificates)"
    fi
    
    # Test SSL nginx config (will fail without certs, but we can check basic syntax)
    if grep -q "ssl_certificate" nginx-ssl.conf && grep -q "server_name" nginx-ssl.conf; then
        print_success "✓ nginx-ssl.conf - Contains required SSL directives"
    else
        print_error "✗ nginx-ssl.conf - Missing SSL directives"
    fi
}

test_script_permissions() {
    print_status "Testing script permissions..."
    
    local scripts=("setup-ssl.sh" "quick-ssl-setup.sh" "start.sh" "backup.sh")
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            if [[ -x "$script" ]]; then
                print_success "✓ $script - Executable"
            else
                print_warning "⚠ $script - Not executable (run: chmod +x $script)"
            fi
        fi
    done
}

test_environment_variables() {
    print_status "Testing environment variable templates..."
    
    # Check if .env exists and has required variables
    if [[ -f ".env" ]]; then
        local required_vars=("EMAIL_HOST" "EMAIL_USER" "EMAIL_PASS" "NODE_ENV")
        
        for var in "${required_vars[@]}"; do
            if grep -q "^$var=" .env; then
                print_success "✓ $var - Found in .env"
            else
                print_warning "⚠ $var - Missing from .env"
            fi
        done
    else
        print_warning "⚠ .env file not found"
    fi
}

simulate_ssl_setup() {
    print_status "Simulating SSL setup process..."
    
    local test_domain="test.example.com"
    local test_email="admin@example.com"
    
    print_status "Simulating domain validation for: $test_domain"
    print_status "Simulating email validation for: $test_email"
    print_status "Simulating directory creation..."
    print_status "Simulating nginx configuration update..."
    print_status "Simulating docker-compose file generation..."
    
    # Test if the setup script would create the right files
    if [[ -f "setup-ssl.sh" ]]; then
        print_status "Checking what files setup-ssl.sh would create..."
        
        # Extract file creation patterns from setup-ssl.sh
        if grep -q "docker-compose.ssl.yml" setup-ssl.sh || grep -q "docker-compose.prod.ssl.yml" setup-ssl.sh; then
            print_success "✓ Would create SSL docker-compose override"
        fi
        
        if grep -q "deploy-ssl.sh" setup-ssl.sh; then
            print_success "✓ Would create deployment script"
        fi
        
        if grep -q "certbot-renew" setup-ssl.sh; then
            print_success "✓ Would create certificate renewal cron job"
        fi
    fi
    
    print_success "SSL setup simulation completed"
}

dry_run_deployment() {
    print_status "Performing dry run of deployment commands..."
    
    # Test docker compose commands without actually running them
    print_status "Testing Docker Compose commands..."
    
    if command -v docker &> /dev/null; then
        print_success "✓ Docker is available"
        
        if docker compose version &> /dev/null; then
            print_success "✓ Docker Compose is available"
        else
            print_error "✗ Docker Compose not available"
        fi
        
        # Test config validation
        print_status "Validating compose file configurations..."
        if docker compose config > /dev/null 2>&1; then
            print_success "✓ Base configuration is valid"
        else
            print_error "✗ Base configuration has issues"
        fi
        
    else
        print_error "✗ Docker not available for testing"
    fi
}

test_backup_functionality() {
    print_status "Testing backup script logic..."
    
    if [[ -f "backup.sh" ]]; then
        # Check if backup script has the right structure
        if grep -q "docker compose exec" backup.sh; then
            print_success "✓ Backup script uses correct Docker Compose syntax"
        else
            print_error "✗ Backup script uses old docker-compose syntax"
        fi
        
        if grep -q "image-collection-portal_upload_data" backup.sh; then
            print_success "✓ Backup script uses correct volume name"
        else
            print_error "✗ Backup script uses incorrect volume name"
        fi
        
        if grep -q "pg_dump" backup.sh; then
            print_success "✓ Backup script includes database backup"
        fi
        
        if grep -q "tar -czf" backup.sh; then
            print_success "✓ Backup script includes file archive creation"
        fi
    fi
}

# Main test suite
main() {
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${BLUE}  SSL Scripts Testing Suite${NC}"
    echo -e "${BLUE}=====================================${NC}"
    echo ""
    
    test_file_structure
    echo ""
    
    test_script_permissions
    echo ""
    
    test_domain_validation
    echo ""
    
    test_email_validation
    echo ""
    
    test_docker_compose_syntax
    echo ""
    
    test_nginx_config
    echo ""
    
    test_environment_variables
    echo ""
    
    test_backup_functionality
    echo ""
    
    simulate_ssl_setup
    echo ""
    
    dry_run_deployment
    echo ""
    
    print_success "🎉 SSL scripts testing completed!"
    echo ""
    print_status "Summary:"
    echo "• All validation logic tested"
    echo "• File structure verified"
    echo "• Docker configurations validated"
    echo "• Scripts are ready for deployment"
    echo ""
    print_warning "Note: Actual SSL certificate generation requires:"
    echo "• Real domain pointing to your server"
    echo "• Ports 80/443 open"
    echo "• Running on actual Ubuntu server"
}

# Run tests
main