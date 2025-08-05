# 🏗️ **Technical Architecture & Flow**

## **📦 Container Architecture**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │    Backend      │    │   Database      │
│   (Next.js)     │◄──►│   (Node.js)     │◄──►│  (PostgreSQL)   │
│   Port: 3000    │    │   Port: 3001    │    │   Port: 5432    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │     Nginx       │
                    │   (Reverse      │
                    │    Proxy)       │
                    │   Port: 80/443  │
                    └─────────────────┘
```

## **🔄 Application Flow**

### **1. Startup Sequence**
```bash
# 1. Docker Compose starts all services
docker-compose up -d

# 2. Database initialization
postgres:15-alpine
├── Creates database: image_collection_db
├── Runs init-db.sql
└── Creates tables: students, student_images, otps

# 3. Backend startup
node:18-alpine
├── Loads .env configuration
├── Connects to PostgreSQL
├── Creates tables (if not exist)
└── Starts Express server on port 3001

# 4. Frontend startup
next:18-alpine
├── Builds Next.js application
├── Starts development server
└── Serves on port 3000

# 5. Nginx startup
nginx:alpine
├── Loads nginx.conf
├── Proxies frontend requests to port 3000
├── Proxies API requests to port 3001
└── Serves static files
```

### **2. User Flow**

#### **Step 1: Consent Form**
```
User → Frontend (http://localhost:3000)
├── Fills consent form
├── Enters IITK email (@iitk.ac.in)
└── Clicks "Send OTP"
```

#### **Step 2: Email Validation & OTP**
```
Frontend → Backend API (/api/send-otp)
├── Validates email domain (@iitk.ac.in)
├── Development Mode: Bypasses email sending
├── Production Mode: Sends real email via SMTP
└── Stores OTP hash in database
```

#### **Step 3: OTP Verification**
```
User → Frontend → Backend API (/api/verify-otp)
├── Enters OTP from email
├── Development Mode: Accepts any OTP
├── Production Mode: Verifies against database
└── Returns success/failure
```

#### **Step 4: Image Upload**
```
User → Frontend → Backend API (/api/submit)
├── Uploads images with age metadata
├── Backend processes with Multer
├── Stores files in /app/data/student_uploads/
├── Saves metadata to database
└── Returns success message
```

## **📁 File Structure & Data Flow**

### **Backend File Storage**
```
/app/data/
├── student_uploads/
│   └── {student_id}/
│       ├── image1.jpg
│       ├── image2.jpg
│       └── ...
└── consent_form/
    └── {student_id}/
        └── consent.pdf
```

### **Database Schema**
```sql
-- Students table
CREATE TABLE students (
    id UUID PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    roll_number VARCHAR(50),
    department VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Student images table
CREATE TABLE student_images (
    id UUID PRIMARY KEY,
    student_id UUID REFERENCES students(id),
    image_path VARCHAR(500),
    age INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

-- OTP table
CREATE TABLE otps (
    id UUID PRIMARY KEY,
    email VARCHAR(255),
    otp_hash VARCHAR(255),
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);
```

## **🔧 Configuration Files**

### **1. Docker Compose (docker-compose.yml)**
```yaml
services:
  postgres:    # Database
  backend:     # Node.js API
  frontend:    # Next.js App
  nginx:       # Reverse Proxy
```

### **2. Environment Variables (.env)**
```bash
# Database
DB_USER=portal_user
DB_HOST=postgres
DB_DATABASE=image_collection_db
DB_PASSWORD=portal_password
DB_PORT=5432

# Email (Production)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your.email@gmail.com
EMAIL_PASS=your_app_password

# Server
NODE_ENV=production|development
PORT=3001
```

### **3. Nginx Configuration (nginx.conf)**
```nginx
# Upstream definitions
upstream frontend { server frontend:3000; }
upstream backend { server backend:3001; }

# Proxy rules
location / {
    proxy_pass http://frontend;
}

location /api {
    proxy_pass http://backend;
}

location /uploads {
    proxy_pass http://backend;
}
```

## **🛠️ Development vs Production**

### **Development Mode**
```javascript
// backend/routes/api.js
if (isDevelopment) {
    console.log(`Development mode: OTP request for ${email} - skipping email send`);
    res.status(200).json({ message: 'OTP sent successfully (development mode).' });
    return;
}
```

### **Production Mode**
```javascript
// backend/routes/api.js
try {
    await transporter.sendMail({
        from: `${process.env.EMAIL_USER}`,
        to: email,
        subject: '[Smart Search] Verify email for Image Collection Portal',
        html: `<b>Your OTP is: ${otp}</b>`
    });
} catch (emailError) {
    console.error('Email sending failed:', emailError.message);
}
```

## **📊 Monitoring & Logs**

### **Container Logs**
```bash
# View all logs
docker-compose logs

# View specific service
docker-compose logs backend --tail=20

# Follow logs in real-time
docker-compose logs -f backend
```

### **Health Checks**
```bash
# API Health
curl http://localhost:3001/api/health

# Container Status
docker-compose ps

# Database Connection
docker exec image-portal-backend node -e "
const { Pool } = require('pg');
const pool = new Pool();
pool.query('SELECT NOW()', (err, res) => {
    console.log(err ? 'DB Error' : 'DB Connected');
    process.exit(0);
});
"
```

## **🔒 Security Features**

### **1. Email Validation**
- ✅ Only `@iitk.ac.in` emails accepted
- ✅ OTP expiration (10 minutes)
- ✅ Hashed OTP storage

### **2. File Upload Security**
- ✅ File type validation (images only)
- ✅ File size limits
- ✅ Secure file naming (UUID)
- ✅ Non-root container users

### **3. Database Security**
- ✅ Parameterized queries (SQL injection protection)
- ✅ Connection pooling
- ✅ Isolated database container

### **4. Container Security**
- ✅ Non-root users in containers
- ✅ Resource limits
- ✅ Network isolation
- ✅ Read-only filesystems where possible

## **🚀 Deployment Flow**

### **1. Development Deployment**
```bash
# Start in development mode
./switch-mode.sh development

# Access application
http://localhost:3000

# Test without email setup
# Any OTP will work for testing
```

### **2. Production Deployment**
```bash
# Configure email credentials
nano .env

# Switch to production mode
./switch-mode.sh production

# Test real email sending
curl -X POST http://localhost:3001/api/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@iitk.ac.in"}'
```

## **🔄 Backup & Recovery**

### **Database Backup**
```bash
# Create backup
docker exec image-portal-db pg_dump -U portal_user image_collection_db > backup.sql

# Restore backup
docker exec -i image-portal-db psql -U portal_user image_collection_db < backup.sql
```

### **File Backup**
```bash
# Backup uploaded files
tar -czf uploads_backup.tar.gz -C /app/data student_uploads consent_form

# Restore files
tar -xzf uploads_backup.tar.gz -C /app/data
```

## **📈 Performance & Scaling**

### **Current Setup**
- ✅ Single container per service
- ✅ Nginx reverse proxy
- ✅ Connection pooling
- ✅ Static file serving

### **Scaling Options**
- 🔄 Horizontal scaling (multiple backend instances)
- 🔄 Load balancer (HAProxy/Traefik)
- 🔄 Database clustering (PostgreSQL replication)
- 🔄 CDN for static files
- 🔄 Redis for session management

---

**🎯 This architecture provides a robust, scalable, and secure foundation for the image collection portal!** 