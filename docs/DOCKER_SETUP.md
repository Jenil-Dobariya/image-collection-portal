# Docker Setup Guide - Image Collection Portal

This guide provides complete instructions for running the Image Collection Portal using Docker containers.

## 🐳 Prerequisites

- **Docker** (v20.10 or higher)
- **Docker Compose** (v2.0 or higher)
- **Git**
 
## 🚀 Quick Start

### 1. Clone and Navigate
```bash
git clone <repository-url>
cd image-collection-portal
```

### 2. Environment Configuration

Create a `.env` file in the root directory:
```bash
# Email Configuration (Required for OTP functionality)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_app_password

# Optional: Custom ports (defaults shown)
FRONTEND_PORT=3000
BACKEND_PORT=3001
DATABASE_PORT=5432
```

### 3. Build and Start Services
```bash
# Build all containers
docker-compose build

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f
```

### 4. Access the Application
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:3001
- **Database**: localhost:5432
- **Nginx Proxy**: http://localhost:80

## 📋 Service Details

### Database (PostgreSQL)
- **Container**: `image-portal-db`
- **Port**: 5432
- **Database**: `image_collection_db`
- **User**: `portal_user`
- **Password**: `portal_password`
- **Volume**: `postgres_data`

### Backend API
- **Container**: `image-portal-backend`
- **Port**: 3001
- **Health Check**: http://localhost:3001/api/health
- **Volume**: `upload_data` (for file storage)

### Frontend Application
- **Container**: `image-portal-frontend`
- **Port**: 3000
- **Framework**: Next.js 15

### Nginx Reverse Proxy
- **Container**: `image-portal-nginx`
- **Port**: 80
- **Features**: Rate limiting, compression, security headers

## 🔧 Docker Commands

### Basic Operations
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart specific service
docker-compose restart backend

# View logs
docker-compose logs -f backend

# Access container shell
docker-compose exec backend sh
docker-compose exec postgres psql -U portal_user -d image_collection_db
```

### Development Commands
```bash
# Rebuild specific service
docker-compose build backend

# Force rebuild (no cache)
docker-compose build --no-cache

# View service status
docker-compose ps

# Scale services (if needed)
docker-compose up -d --scale backend=2
```

### Database Operations
```bash
# Access PostgreSQL
docker-compose exec postgres psql -U portal_user -d image_collection_db

# Backup database
docker-compose exec postgres pg_dump -U portal_user image_collection_db > backup.sql

# Restore database
docker-compose exec -T postgres psql -U portal_user -d image_collection_db < backup.sql
```

## 🔍 Monitoring and Debugging

### Health Checks
```bash
# Check all services
docker-compose ps

# Test API health
curl http://localhost:3001/api/health

# Test frontend
curl http://localhost:3000
```

### Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f postgres
docker-compose logs -f nginx
```

### Resource Usage
```bash
# Container stats
docker stats

# Disk usage
docker system df
```

## 🛠️ Configuration Options

### Custom Ports
Edit `docker-compose.yml` to change ports:
```yaml
services:
  frontend:
    ports:
      - "8080:3000"  # Change 8080 to your preferred port
```

### Environment Variables
Add to `.env` file:
```env
# Custom database settings
POSTGRES_DB=custom_db_name
POSTGRES_USER=custom_user
POSTGRES_PASSWORD=custom_password

# Custom ports
FRONTEND_PORT=8080
BACKEND_PORT=8081
```

### Volume Mounts
For development, you can mount source code:
```yaml
services:
  backend:
    volumes:
      - ./backend:/app
      - /app/node_modules
```

## 🔒 Security Considerations

### Production Deployment
1. **Change default passwords**
2. **Use environment variables for secrets**
3. **Enable HTTPS with SSL certificates**
4. **Configure firewall rules**
5. **Set up monitoring and logging**

### SSL/HTTPS Setup
1. Obtain SSL certificates
2. Update `nginx.conf` with SSL configuration
3. Uncomment HTTPS server block
4. Restart nginx container

### Network Security
```bash
# Create custom network
docker network create portal-network

# Use internal network only
docker-compose up -d --network portal-network
```

## 📊 Performance Optimization

### Resource Limits
Add to `docker-compose.yml`:
```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
```

### Caching
- **Database**: PostgreSQL query cache
- **Frontend**: Next.js static generation
- **Nginx**: Static file caching

### Scaling
```bash
# Scale backend instances
docker-compose up -d --scale backend=3

# Use load balancer
# Configure nginx upstream with multiple backend instances
```

## 🧹 Maintenance

### Regular Tasks
```bash
# Update images
docker-compose pull

# Clean up unused resources
docker system prune -f

# Backup volumes
docker run --rm -v portal_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_backup.tar.gz -C /data .
```

### Troubleshooting

#### Common Issues

1. **Port conflicts**
   ```bash
   # Check what's using the port
   netstat -tulpn | grep :3000
   
   # Change ports in docker-compose.yml
   ```

2. **Database connection errors**
   ```bash
   # Check database logs
   docker-compose logs postgres
   
   # Restart database
   docker-compose restart postgres
   ```

3. **File upload issues**
   ```bash
   # Check volume permissions
   docker-compose exec backend ls -la /app/data
   
   # Fix permissions
   docker-compose exec backend chown -R nodejs:nodejs /app/data
   ```

4. **Email not sending**
   ```bash
   # Check email configuration
   docker-compose exec backend env | grep EMAIL
   
   # Test email service
   docker-compose exec backend node -e "console.log(process.env.EMAIL_HOST)"
   ```

## 🚀 Production Deployment

### 1. Environment Setup
```bash
# Create production .env
cp .env.example .env.prod

# Edit with production values
nano .env.prod
```

### 2. SSL Certificate
```bash
# Generate self-signed certificate (for testing)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/key.pem \
  -out nginx/ssl/cert.pem
```

### 3. Production Commands
```bash
# Build production images
docker-compose -f docker-compose.yml -f docker-compose.prod.yml build

# Start production stack
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Monitor logs
docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f
```

### 4. Backup Strategy
```bash
#!/bin/bash
# backup.sh
DATE=$(date +%Y%m%d_%H%M%S)
docker-compose exec postgres pg_dump -U portal_user image_collection_db > backup_$DATE.sql
tar -czf uploads_backup_$DATE.tar.gz -C /var/lib/docker/volumes/portal_upload_data/_data .
```

## 📝 Development Workflow

### Local Development
```bash
# Start services
docker-compose up -d postgres backend

# Run frontend locally
cd frontend
npm install
npm run dev
```

### Testing
```bash
# Run tests in containers
docker-compose exec backend npm test
docker-compose exec frontend npm test
```

### Code Changes
```bash
# Rebuild after code changes
docker-compose build backend
docker-compose up -d backend

# Hot reload (mount volumes)
docker-compose up -d
```

## 🆘 Support

### Useful Commands
```bash
# View all containers
docker ps -a

# View all images
docker images

# View all volumes
docker volume ls

# View all networks
docker network ls

# Clean everything
docker system prune -a --volumes
```

### Debugging
```bash
# Inspect container
docker inspect image-portal-backend

# View container logs
docker logs image-portal-backend

# Execute commands in container
docker exec -it image-portal-backend sh
```

---

**Note**: This Docker setup provides a complete, production-ready environment for the Image Collection Portal. All services are containerized with proper networking, volumes, and health checks. 