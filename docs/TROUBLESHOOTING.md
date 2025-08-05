# 🔧 Troubleshooting Guide - Docker Build Issues

## 🚨 Common Issues and Solutions

### 1. npm Timeout Error (EIDLETIMEOUT)

**Error:**
```
npm error code EIDLETIMEOUT
npm error Idle timeout reached for host `registry.npmjs.org:443`
```

**Solutions:**

#### Option A: Use Updated Dockerfiles (Recommended)
The Dockerfiles have been updated with better timeout settings. Try rebuilding:

```bash
# Clean up and rebuild
docker-compose down
docker system prune -f
docker-compose build --no-cache
```

#### Option B: Use Yarn Alternative
If npm continues to fail, use the yarn-based Dockerfiles:

```bash
# Rename Dockerfiles to use yarn
mv backend/Dockerfile backend/Dockerfile.npm
mv backend/Dockerfile.yarn backend/Dockerfile

mv frontend/Dockerfile frontend/Dockerfile.npm
mv frontend/Dockerfile.yarn frontend/Dockerfile

# Rebuild
docker-compose build --no-cache
```

#### Option C: Manual Network Configuration
```bash
# Set npm registry and timeout
docker-compose exec backend npm config set registry https://registry.npmjs.org/
docker-compose exec backend npm config set fetch-timeout 300000
```

### 2. Network Connectivity Issues

**Check your internet connection:**
```bash
# Test npm registry
curl -I https://registry.npmjs.org/

# Test DNS
nslookup registry.npmjs.org

# Check Docker network
docker network ls
docker network inspect portal-network
```

**Use alternative npm registry:**
```bash
# Set alternative registry
npm config set registry https://registry.npm.taobao.org/
```

### 3. Docker Build Context Issues

**Clean Docker cache:**
```bash
# Remove all unused containers, networks, images
docker system prune -a

# Remove specific images
docker rmi $(docker images -q)

# Clean build cache
docker builder prune -a
```

### 4. Memory/Resource Issues

**Increase Docker resources:**
- Open Docker Desktop
- Go to Settings > Resources
- Increase Memory (at least 4GB)
- Increase CPU (at least 2 cores)

**Check system resources:**
```bash
# Check available memory
free -h

# Check disk space
df -h

# Check Docker disk usage
docker system df
```

### 5. Port Conflicts

**Check for port conflicts:**
```bash
# Check what's using the ports
netstat -tulpn | grep :3000
netstat -tulpn | grep :3001
netstat -tulpn | grep :5432

# Kill processes using ports (if needed)
sudo kill -9 <PID>
```

**Change ports in docker-compose.yml:**
```yaml
services:
  frontend:
    ports:
      - "8080:3000"  # Change to different port
  backend:
    ports:
      - "8081:3001"  # Change to different port
```

### 6. Permission Issues

**Fix file permissions:**
```bash
# Make scripts executable
chmod +x start.sh
chmod +x backup.sh

# Fix Docker volume permissions
sudo chown -R $USER:$USER /var/lib/docker/volumes/
```

### 7. Alternative Build Methods

#### Method 1: Build with BuildKit
```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1

# Build with BuildKit
docker-compose build --progress=plain
```

#### Method 2: Build Individual Services
```bash
# Build backend only
docker-compose build backend

# Build frontend only
docker-compose build frontend

# Start services
docker-compose up -d
```

#### Method 3: Use Different Base Images
Update Dockerfiles to use different Node.js versions:

```dockerfile
# Try different Node.js version
FROM node:16-alpine
# or
FROM node:20-alpine
```

### 8. Development Mode (Skip Docker)

If Docker continues to fail, you can run the application without Docker:

```bash
# Backend setup
cd backend
npm install
npm run dev

# Frontend setup (in new terminal)
cd frontend
npm install
npm run dev
```

### 9. Debugging Commands

**Check container logs:**
```bash
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs backend
docker-compose logs frontend

# Follow logs in real-time
docker-compose logs -f
```

**Inspect containers:**
```bash
# List running containers
docker ps

# Inspect container
docker inspect image-portal-backend

# Execute commands in container
docker-compose exec backend sh
docker-compose exec postgres psql -U portal_user -d image_collection_db
```

**Check network connectivity:**
```bash
# Test network from container
docker-compose exec backend ping google.com
docker-compose exec backend curl -I https://registry.npmjs.org/
```

### 10. Environment-Specific Issues

#### Windows Issues
```bash
# Use WSL2 for better performance
# Enable WSL2 in Docker Desktop settings

# Fix line endings
git config --global core.autocrlf false
```

#### macOS Issues
```bash
# Increase Docker Desktop resources
# Memory: 4GB+, CPU: 2+

# Check Docker Desktop settings
# Enable "Use the WSL 2 based engine"
```

#### Linux Issues
```bash
# Install Docker properly
sudo apt-get update
sudo apt-get install docker.io docker-compose

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### 11. Production Deployment Issues

**Use production compose file:**
```bash
# Production deployment
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Check production logs
docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f
```

**Resource limits:**
```bash
# Check resource usage
docker stats

# Adjust resource limits in docker-compose.prod.yml
```

### 12. Getting Help

**Collect diagnostic information:**
```bash
# System information
docker version
docker-compose version
node --version
npm --version

# Docker system info
docker system info

# Container status
docker-compose ps

# Recent logs
docker-compose logs --tail=100
```

**Common solutions summary:**
1. ✅ **Clean and rebuild**: `docker-compose down && docker system prune -f && docker-compose build --no-cache`
2. ✅ **Use yarn**: Rename Dockerfile.yarn to Dockerfile
3. ✅ **Increase resources**: More memory/CPU in Docker Desktop
4. ✅ **Check network**: Test internet connectivity
5. ✅ **Alternative ports**: Change ports in docker-compose.yml
6. ✅ **Development mode**: Run without Docker if needed

---

**💡 Pro Tip**: If you continue to have issues, try the development mode setup (without Docker) as a fallback option. 