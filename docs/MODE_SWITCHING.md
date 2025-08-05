# 🔄 **Mode Switching Quick Reference**

## **🚀 Quick Commands**

### **Switch to Development Mode**
```bash
./switch-mode.sh development
```
**What happens:**
- ✅ Email sending bypassed
- ✅ Any OTP accepted for testing
- ✅ No email credentials required
- ✅ Perfect for local development

### **Switch to Production Mode**
```bash
./switch-mode.sh production
```
**What happens:**
- ✅ Real email sending enabled
- ✅ OTP verification required
- ✅ Email credentials must be configured
- ✅ Ready for live deployment

---

## **🧪 Testing Each Mode**

### **Development Mode Test**
```bash
# 1. Switch to development
./switch-mode.sh development

# 2. Test OTP sending (should bypass email)
curl -X POST http://localhost:3001/api/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@iitk.ac.in"}'
# Expected: {"message":"OTP sent successfully (development mode)."}

# 3. Test OTP verification (should accept any OTP)
curl -X POST http://localhost:3001/api/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@iitk.ac.in","otp":"123456"}'
# Expected: {"message":"Email verified successfully (development mode)."}
```

### **Production Mode Test**
```bash
# 1. Configure email credentials first
nano .env
# Update EMAIL_USER and EMAIL_PASS

# 2. Switch to production
./switch-mode.sh production

# 3. Test OTP sending (should send real email)
curl -X POST http://localhost:3001/api/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@iitk.ac.in"}'
# Expected: {"message":"OTP sent successfully."}

# 4. Check email for OTP and verify
curl -X POST http://localhost:3001/api/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@iitk.ac.in","otp":"RECEIVED_OTP"}'
# Expected: {"message":"Email verified successfully."}
```

---

## **📊 Mode Comparison**

| Feature | Development | Production |
|---------|-------------|------------|
| **Email Sending** | ❌ Bypassed | ✅ Real SMTP |
| **OTP Verification** | ❌ Any OTP works | ✅ Database check |
| **Email Credentials** | ❌ Not required | ✅ Required |
| **Database Operations** | ✅ Full | ✅ Full |
| **File Uploads** | ✅ Working | ✅ Working |
| **Email Validation** | ✅ `@iitk.ac.in` only | ✅ `@iitk.ac.in` only |
| **Logging** | 🔍 Verbose | 🔍 Standard |

---

## **🔧 Manual Mode Switching**

### **Method 1: Edit docker-compose.yml**
```bash
# Development
sed -i 's/NODE_ENV=production/NODE_ENV=development/' docker-compose.yml

# Production
sed -i 's/NODE_ENV=development/NODE_ENV=production/' docker-compose.yml

# Restart
docker-compose down && docker-compose up -d
```

### **Method 2: Environment Variable**
```bash
# Set in .env file
NODE_ENV=development  # or production

# Restart backend only
docker-compose restart backend
```

---

## **🚨 Troubleshooting**

### **Issue: Mode not switching**
```bash
# Check current mode
docker-compose logs backend | grep "NODE_ENV"

# Force restart
docker-compose down
docker-compose up -d

# Check logs
docker-compose logs backend --tail=10
```

### **Issue: Email not working in production**
```bash
# 1. Check credentials
cat .env | grep EMAIL

# 2. Test email configuration
./test-email.sh

# 3. Check backend logs
docker-compose logs backend --tail=20
```

### **Issue: OTP verification failing**
```bash
# Development mode: Any OTP should work
# Production mode: Check email for actual OTP

# Test with curl
curl -X POST http://localhost:3001/api/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@iitk.ac.in","otp":"123456"}'
```

---

## **📝 Best Practices**

### **Development Workflow**
1. ✅ Start in development mode
2. ✅ Test without email setup
3. ✅ Use any OTP for testing
4. ✅ Focus on UI/UX testing

### **Production Workflow**
1. ✅ Configure email credentials
2. ✅ Switch to production mode
3. ✅ Test real email sending
4. ✅ Verify complete user flow

### **Testing Checklist**
- [ ] Email domain validation (`@iitk.ac.in`)
- [ ] OTP sending (development/production)
- [ ] OTP verification
- [ ] Image upload functionality
- [ ] Database storage
- [ ] File storage and access

---

## **🎯 Quick Start Commands**

```bash
# Development (no email setup needed)
./switch-mode.sh development
# Access: http://localhost:3000
# Test with any OTP

# Production (email setup required)
./setup-email.sh
nano .env  # Add your email credentials
./switch-mode.sh production
# Access: http://localhost:3000
# Test with real email OTP
```

**�� Happy testing!** 