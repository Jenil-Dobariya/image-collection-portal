# 🚀 Final Deployment Steps - IITK Domain

The `./deploy-ssl-iitk.sh` script is **COMPLETE** and handles everything. It replaces `start.sh` for production deployment.

---

## 📋 **Complete Deployment Process (4 Steps)**

### **Step 1: Server Preparation**
```bash
# On your Ubuntu server
sudo apt update && sudo apt upgrade -y

# Install Docker (if not already installed)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose-plugin

# Verify installation
docker --version
docker compose version
```

### **Step 2: Upload Project & Configure**
```bash
# Upload your project to server (via git/scp/etc.)
git clone <your-repo> smart-search-rescue
cd smart-search-rescue

# Create/edit .env file
nano .env
```

**Required .env content:**
```bash
NODE_ENV=production

# Database
DB_USER=portal_user
DB_HOST=postgres
DB_DATABASE=image_collection_db
DB_PASSWORD=your_secure_password

# Email (for OTP)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_app_password
```

### **Step 3: SSL Setup (One-time)**
```bash
# Generate SSL certificates for your domain
sudo ./setup-ssl.sh

# When prompted:
# Domain: smartsearch.iitk.ac.in
# Email: your_username@iitk.ac.in
```

### **Step 4: Deploy Application**
```bash
# This single command does EVERYTHING
sudo ./deploy-ssl-iitk.sh
```

---

## ✅ **What `deploy-ssl-iitk.sh` Does (Complete Deployment)**

### **🔧 The Script Handles:**
1. ✅ **Checks** SSL certificates exist
2. ✅ **Updates** nginx config with your domain
3. ✅ **Stops** any existing containers
4. ✅ **Builds** all Docker images (frontend, backend, database)
5. ✅ **Starts** all services with SSL configuration
6. ✅ **Waits** for services to be ready
7. ✅ **Tests** HTTPS endpoints
8. ✅ **Verifies** SSL certificate
9. ✅ **Reports** deployment status

### **🚫 You DON'T Need:**
- ❌ `start.sh` (for development only)
- ❌ Manual Docker commands
- ❌ Separate nginx setup
- ❌ Manual SSL configuration

---

## 🎯 **Final Result**

### **✅ After Running `sudo ./deploy-ssl-iitk.sh`:**

**Your application will be live at:**
```
🌐 https://smartsearch.iitk.ac.in
```

**All endpoints accessible:**
- 📱 Main app: `https://smartsearch.iitk.ac.in`
- 🔍 Health check: `https://smartsearch.iitk.ac.in/api/health`
- 📧 Send OTP: `https://smartsearch.iitk.ac.in/api/send-otp`
- ✅ Verify OTP: `https://smartsearch.iitk.ac.in/api/verify-otp`
- 📤 Submit form: `https://smartsearch.iitk.ac.in/api/submit`

---

## 🔍 **Verification Steps**

### **1. Check Deployment Success:**
```bash
# Check if all containers are running
docker compose ps

# Should show all services as "Up"
```

### **2. Test Application:**
```bash
# Test health endpoint
curl https://smartsearch.iitk.ac.in/api/health

# Expected: {"status":"OK","timestamp":"..."}
```

### **3. Test in Browser:**
```
Visit: https://smartsearch.iitk.ac.in
```
- ✅ Green lock icon (SSL working)
- ✅ Application loads
- ✅ Can fill forms and send OTP

---

## 🆘 **If Something Goes Wrong**

### **Check Logs:**
```bash
# View all logs
docker compose logs -f

# View specific service logs
docker compose logs nginx
docker compose logs backend
docker compose logs frontend
```

### **Restart Services:**
```bash
# Restart all services
docker compose restart

# Or restart specific service
docker compose restart nginx
```

### **Complete Redeploy:**
```bash
# If needed, run deployment again
sudo ./deploy-ssl-iitk.sh
```

---

## 📋 **Complete Command Summary**

### **For Fresh Server:**
```bash
# 1. Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh

# 2. Clone project
git clone <your-repo> smart-search-rescue && cd smart-search-rescue

# 3. Configure environment
nano .env  # Add email settings

# 4. Setup SSL
sudo ./setup-ssl.sh  # Enter: smartsearch.iitk.ac.in, your@iitk.ac.in

# 5. Deploy (COMPLETE)
sudo ./deploy-ssl-iitk.sh
```

### **For Updates/Redeployment:**
```bash
# Just run this single command
sudo ./deploy-ssl-iitk.sh
```

---

## 🎉 **Success Indicators**

### **✅ Deployment Successful When You See:**
```
🎉 ========================================
   DEPLOYMENT SUCCESSFUL!
========================================

Your Smart Search and Rescue Project is now live!

🌐 Application URLs:
   Main Application: https://smartsearch.iitk.ac.in
   API Health Check: https://smartsearch.iitk.ac.in/api/health
```

### **🔒 SSL Working When:**
- ✅ Browser shows green lock icon
- ✅ HTTP redirects to HTTPS automatically
- ✅ Certificate shows as valid

---

## ⚡ **Quick Answer Summary**

**Question:** *Do I need to run start.sh before deploy-ssl-iitk.sh?*

**Answer:** **NO** - `deploy-ssl-iitk.sh` is complete and handles everything:
- `start.sh` = Development deployment
- `deploy-ssl-iitk.sh` = Production deployment with SSL

**Single command for production:**
```bash
sudo ./deploy-ssl-iitk.sh
```

**Result:** Complete production deployment at `https://smartsearch.iitk.ac.in` 🚀