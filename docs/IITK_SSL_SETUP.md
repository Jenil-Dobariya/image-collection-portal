# 🏛️ IITK Domain SSL Setup Guide

## 🌐 Your Domain: `smartsearch.iitk.ac.in`

### **Email Setup for Let's Encrypt**

Since you don't have a specific email for the domain, you can use:

#### **Option 1: Use Your Personal IITK Email**
```bash
# Use your existing IITK email
your_username@iitk.ac.in
```

#### **Option 2: Use Admin Email (Recommended)**
```bash
# Common admin emails that work with Let's Encrypt
admin@iitk.ac.in
webmaster@iitk.ac.in
hostmaster@iitk.ac.in
```

#### **Option 3: Use Your Personal Email**
```bash
# Any valid email you have access to
your_personal_email@gmail.com
```

**Note**: The email is only used for Let's Encrypt certificate expiry notifications, not for domain validation.

---

## 🚀 Complete Deployment Process

### **Command You'll Run:**
```bash
sudo ./deploy-ssl.sh
```

### **What This Command Does:**

1. **Stops existing containers** (if any)
2. **Builds all Docker images** (frontend, backend)
3. **Starts all services with SSL** using:
   - `docker-compose.yml` (base configuration)
   - `docker-compose.prod.ssl.yml` (SSL overrides)
4. **Waits for services** to become healthy
5. **Performs health checks** to verify deployment
6. **Reports success/failure**

---

## 🌐 Application URLs After Deployment

### **🔒 HTTPS (Primary Access)**
```
https://smartsearch.iitk.ac.in
```

### **📱 Specific Endpoints:**

| Service | URL | Description |
|---------|-----|-------------|
| **Main Application** | `https://smartsearch.iitk.ac.in` | Frontend (Next.js) |
| **API Health Check** | `https://smartsearch.iitk.ac.in/api/health` | Backend health |
| **Send OTP** | `https://smartsearch.iitk.ac.in/api/send-otp` | OTP endpoint |
| **Verify OTP** | `https://smartsearch.iitk.ac.in/api/verify-otp` | OTP verification |
| **Submit Form** | `https://smartsearch.iitk.ac.in/api/submit` | Form submission |
| **Static Images** | `https://smartsearch.iitk.ac.in/uploads/{student-id}/1.jpg` | Uploaded images |

### **🔓 HTTP (Auto-Redirects to HTTPS)**
```
http://smartsearch.iitk.ac.in  →  https://smartsearch.iitk.ac.in
```

---

## 🔌 Port Configuration

### **External Ports (Accessible from Internet):**
| Port | Protocol | Service | Access |
|------|----------|---------|---------|
| **80** | HTTP | Nginx (Redirect) | `http://smartsearch.iitk.ac.in` |
| **443** | HTTPS | Nginx (SSL) | `https://smartsearch.iitk.ac.in` |

### **Internal Ports (Container-to-Container):**
| Port | Service | Internal Use |
|------|---------|--------------|
| 3000 | Frontend | Nginx → Frontend |
| 3001 | Backend | Nginx → Backend |
| 5432 | PostgreSQL | Backend → Database |

---

## 📋 Pre-Deployment Steps

### **1. SSL Certificate Setup**
```bash
# Run SSL setup first (one-time)
sudo ./setup-ssl.sh

# When prompted, enter:
# Domain: smartsearch.iitk.ac.in
# Email: your_username@iitk.ac.in (or admin@iitk.ac.in)
```

### **2. Environment Configuration**
Update your `.env` file:
```bash
NODE_ENV=production
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_app_password
```

### **3. DNS Verification**
```bash
# Verify domain points to your server
nslookup smartsearch.iitk.ac.in

# Should return your server's IP address
```

---

## 🛠️ Complete Deployment Sequence

### **Step 1: Initial SSL Setup**
```bash
# One-time SSL certificate generation
sudo ./setup-ssl.sh
```

### **Step 2: Deploy Application**
```bash
# Deploy with SSL
sudo ./deploy-ssl.sh
```

### **Step 3: Verification**
```bash
# Check if application is running
curl -f https://smartsearch.iitk.ac.in/api/health

# Expected response:
# {"status":"OK","timestamp":"2025-01-30T..."}
```

---

## 🔍 Deployment Process Details

### **What `./deploy-ssl.sh` Actually Runs:**
```bash
#!/bin/bash

# 1. Check SSL certificates exist
if [ ! -f "/etc/letsencrypt/live/smartsearch.iitk.ac.in/fullchain.pem" ]; then
    echo "SSL certificates not found. Run setup-ssl.sh first."
    exit 1
fi

# 2. Stop existing containers
docker compose down

# 3. Build and start with SSL
docker compose -f docker-compose.yml -f docker-compose.prod.ssl.yml up -d --build

# 4. Wait for services
sleep 30

# 5. Health check
if curl -f -s https://smartsearch.iitk.ac.in/health > /dev/null; then
    echo "🎉 SSL deployment successful!"
    echo "Your application is available at: https://smartsearch.iitk.ac.in"
else
    echo "❌ Health check failed"
fi
```

---

## 🎯 After Deployment Success

### **✅ Your Application Will Be Available At:**
```
🌐 Main URL: https://smartsearch.iitk.ac.in
📱 Mobile-friendly interface
🔒 SSL-secured with Let's Encrypt certificate
🚀 Production-optimized performance
```

### **🔧 Management Commands:**
```bash
# View logs
docker compose logs -f

# Check status
docker compose ps

# Restart services
docker compose restart

# Stop application
docker compose down
```

---

## 🚨 Troubleshooting

### **If Deployment Fails:**

#### **1. Check DNS Resolution**
```bash
nslookup smartsearch.iitk.ac.in
# Should return your server IP
```

#### **2. Check SSL Certificates**
```bash
sudo certbot certificates
# Should show smartsearch.iitk.ac.in certificate
```

#### **3. Check Docker Services**
```bash
docker compose ps
# All services should show "Up" status
```

#### **4. Check Logs**
```bash
docker compose logs nginx
docker compose logs backend
docker compose logs frontend
```

#### **5. Manual Health Check**
```bash
# Test from server
curl -f https://smartsearch.iitk.ac.in/api/health

# Test SSL certificate
openssl s_client -connect smartsearch.iitk.ac.in:443 -servername smartsearch.iitk.ac.in
```

---

## 🎉 Success Indicators

### **✅ Deployment Successful When:**
- ✅ `https://smartsearch.iitk.ac.in` loads the application
- ✅ SSL certificate shows as valid (green lock in browser)
- ✅ `https://smartsearch.iitk.ac.in/api/health` returns `{"status":"OK"}`
- ✅ All Docker containers show "Up" status
- ✅ HTTP automatically redirects to HTTPS

### **🎯 Final Result:**
Your **Smart Search and Rescue Project** will be live at:
```
🌐 https://smartsearch.iitk.ac.in
```

With full SSL encryption, production optimization, and professional configuration! 🚀