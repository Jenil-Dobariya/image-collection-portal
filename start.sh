#!/bin/bash

# Image Collection Portal - Docker Startup Script
# This script sets up and starts the complete application stack

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if Docker is installed
check_docker() {
    print_status "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_success "Docker and Docker Compose are installed"
}

# Check if .env file exists
check_env() {
    print_status "Checking environment configuration..."
    if [ ! -f .env ]; then
        print_warning ".env file not found. Creating default .env file..."
        cat > .env << EOF
# Email Configuration (Required for OTP functionality)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_app_password

# Optional: Custom ports (defaults shown)
FRONTEND_PORT=3000
BACKEND_PORT=3001
DATABASE_PORT=5432

# Production settings (optional)
POSTGRES_PASSWORD=portal_password
NGINX_HOST=localhost
NEXT_PUBLIC_API_URL=http://localhost:3001/api
EOF
        print_warning "Please edit .env file with your email configuration before starting the application."
        print_warning "For Gmail, you need to enable 2FA and generate an App Password."
    else
        print_success "Environment file found"
    fi
}

# Create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    mkdir -p nginx/logs
    mkdir -p nginx/ssl
    print_success "Directories created"
}

# Build Docker images
build_images() {
    print_status "Building Docker images..."
    
    # Check if build fails due to npm timeout
    if ! docker compose build; then
        print_warning "Build failed. Trying with yarn alternative..."
        
        # Try yarn-based Dockerfiles
        if [ -f "backend/Dockerfile.yarn" ] && [ -f "frontend/Dockerfile.yarn" ]; then
            print_status "Switching to yarn-based Dockerfiles..."
            mv backend/Dockerfile backend/Dockerfile.npm
            mv backend/Dockerfile.yarn backend/Dockerfile
            mv frontend/Dockerfile frontend/Dockerfile.npm
            mv frontend/Dockerfile.yarn frontend/Dockerfile
            
            if docker compose build; then
                print_success "Docker images built successfully with yarn"
            else
                print_error "Build failed with yarn as well. Trying development mode..."
                print_warning "Please check TROUBLESHOOTING.md for solutions"
                exit 1
            fi
        else
            print_error "Build failed and yarn alternatives not found"
            print_warning "Please check TROUBLESHOOTING.md for solutions"
            exit 1
        fi
    else
        print_success "Docker images built successfully"
    fi
}

# Start services
start_services() {
    print_status "Starting services..."
    docker compose up -d
    print_success "Services started successfully"
}

# Wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    # Wait for database
    print_status "Waiting for database..."
    timeout=60
    counter=0
    while ! docker compose exec -T postgres pg_isready -U portal_user -d image_collection_db > /dev/null 2>&1; do
        sleep 2
        counter=$((counter + 2))
        if [ $counter -ge $timeout ]; then
            print_error "Database failed to start within $timeout seconds"
            exit 1
        fi
    done
    print_success "Database is ready"
    
    # Wait for backend
    print_status "Waiting for backend API..."
    timeout=60
    counter=0
    while ! curl -f http://localhost:3001/api/health > /dev/null 2>&1; do
        sleep 2
        counter=$((counter + 2))
        if [ $counter -ge $timeout ]; then
            print_error "Backend API failed to start within $timeout seconds"
            exit 1
        fi
    done
    print_success "Backend API is ready"
    
    # Wait for frontend
    print_status "Waiting for frontend..."
    timeout=60
    counter=0
    while ! curl -f http://localhost:3000 > /dev/null 2>&1; do
        sleep 2
        counter=$((counter + 2))
        if [ $counter -ge $timeout ]; then
            print_error "Frontend failed to start within $timeout seconds"
            exit 1
        fi
    done
    print_success "Frontend is ready"
}

# Show service status
show_status() {
    print_status "Service Status:"
    docker compose ps
    
    echo ""
    print_status "Application URLs:"
    echo -e "  ${GREEN}Frontend:${NC} http://localhost:3000"
    echo -e "  ${GREEN}Backend API:${NC} http://localhost:3001"
    echo -e "  ${GREEN}Nginx Proxy:${NC} http://localhost:80"
    echo -e "  ${GREEN}Health Check:${NC} http://localhost:3001/api/health"
    
    echo ""
    print_status "Useful Commands:"
    echo -e "  ${YELLOW}View logs:${NC} docker compose logs -f"
    echo -e "  ${YELLOW}Stop services:${NC} docker compose down"
    echo -e "  ${YELLOW}Restart services:${NC} docker compose restart"
    echo -e "  ${YELLOW}Access database:${NC} docker compose exec postgres psql -U portal_user -d image_collection_db"
}

# Main function
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Image Collection Portal Setup${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    
    check_docker
    check_env
    create_directories
    build_images
    start_services
    wait_for_services
    show_status
    
    echo ""
    print_success "Setup completed successfully!"
    print_warning "Don't forget to configure your email settings in the .env file for OTP functionality."
}

# Handle script arguments
case "${1:-}" in
    "stop")
        print_status "Stopping services..."
        docker compose down
        print_success "Services stopped"
        ;;
    "restart")
        print_status "Restarting services..."
        docker compose restart
        print_success "Services restarted"
        ;;
    "logs")
        print_status "Showing logs..."
        docker compose logs -f
        ;;
    "status")
        print_status "Service status:"
        docker compose ps
        ;;
    "clean")
        print_status "Cleaning up..."
        docker compose down -v
        docker system prune -f
        print_success "Cleanup completed"
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no args)  Start the application"
        echo "  stop       Stop all services"
        echo "  restart    Restart all services"
        echo "  logs       Show service logs"
        echo "  status     Show service status"
        echo "  clean      Stop and remove all containers, networks, and volumes"
        echo "  help       Show this help message"
        ;;
    *)
        main
        ;;
esac 