# 📧 **Complete Email Setup Guide for Production**

## **Step 1: Choose Your Email Provider**

### **Option A: Gmail Setup (Recommended)**

#### **1. Enable 2-Factor Authentication**
1. Go to [Google Account Settings](https://myaccount.google.com/)
2. Navigate to **"Security"** → **"2-Step Verification"**
3. Enable 2-Factor Authentication if not already enabled

#### **2. Generate App Password**
1. Go to [Google AccounVt Settings](https://myaccount.google.com/)
2. Navigate to **"Security"** → **"App passwords"**
3. Select **"Mail"** as the app and **"Other"** as device
4. Click **"Generate"**
5. **Copy the 16-character password** (e.g., `abcd efgh ijkl mnop`)

#### **3. Gmail Credentials**
```bash
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your.email@gmail.com
EMAIL_PASS=your_16_character_app_password
```

---

### **Option B: Outlook Setup**

#### **1. Enable 2-Factor Authentication**
1. Go to [Microsoft Account Security](https://account.microsoft.com/security)
2. Enable 2-Factor Authentication

#### **2. Generate App Password**
1. Go to [Microsoft Account Security](https://account.microsoft.com/security)
2. Navigate to **"Advanced security options"** → **"App passwords"**
3. Generate a new app password
4. **Copy the generated password**

#### **3. Outlook Credentials**
```bash
EMAIL_HOST=smtp-mail.outlook.com
EMAIL_PORT=587
EMAIL_USER=your.email@outlook.com
EMAIL_PASS=your_app_password
```

---

### **Option C: Other SMTP Providers**

#### **Common SMTP Settings**
```bash
# Yahoo
EMAIL_HOST=smtp.mail.yahoo.com
EMAIL_PORT=587

# ProtonMail
EMAIL_HOST=smtp.protonmail.ch
EMAIL_PORT=587

# Custom SMTP
EMAIL_HOST=your.smtp.server.com
EMAIL_PORT=587
```

---

## **Step 2: Create Environment File**

### **Create `.env` file in the root directory:**

```bash
# Copy this template and fill in your credentials
cp .env.example .env
```

### **Fill in your `.env` file:**

```bash
# Database Configuration
DB_USER=portal_user
DB_HOST=postgres
DB_DATABASE=image_collection_db
DB_PASSWORD=portal_password
DB_PORT=5432

# Email Configuration (REQUIRED FOR PRODUCTION)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your.actual.email@gmail.com
EMAIL_PASS=your_actual_app_password

# Server Configuration
NODE_ENV=production
PORT=3001

# Frontend Configuration
NEXT_PUBLIC_API_URL=http://localhost:3001/api
```

---

## **Step 3: Test Email Configuration**

### **1. Update docker-compose.yml for Production**

Edit `docker-compose.yml` and change:
```yaml
environment:
  - NODE_ENV=production  # Change from development to production
```

### **2. Restart the Backend**
```bash
docker-compose down
docker-compose up -d
```

### **3. Test Email Sending**
```bash
# Test the API
curl -X POST http://localhost:3001/api/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@iitk.ac.in"}'
```

### **4. Check Logs**
```bash
docker-compose logs backend --tail=20
```

---

## **Step 4: Troubleshooting**

### **Common Issues & Solutions**

#### **Issue 1: "Invalid login: 535-5.7.8 Username and Password not accepted"**
**Solution:**
- Ensure you're using an **App Password**, not your regular password
- Make sure 2-Factor Authentication is enabled
- Double-check the email and password in `.env`

#### **Issue 2: "Connection timeout"**
**Solution:**
- Check your internet connection
- Verify the SMTP host and port are correct
- Try different ports (587, 465, 25)

#### **Issue 3: "Authentication failed"**
**Solution:**
- Regenerate the app password
- Ensure the email address is correct
- Check if your email provider allows SMTP access

#### **Issue 4: "Less secure app access" (Gmail)**
**Solution:**
- Use App Passwords instead of regular passwords
- Enable 2-Factor Authentication first

---

## **Step 5: Security Best Practices**

### **1. Environment Variables**
- ✅ Use `.env` files (never commit to git)
- ✅ Set `NODE_ENV=production` for production
- ✅ Use App Passwords, not regular passwords

### **2. Email Security**
- ✅ Enable 2-Factor Authentication
- ✅ Use App Passwords for applications
- ✅ Regularly rotate app passwords
- ✅ Monitor email sending logs

### **3. Production Deployment**
- ✅ Use HTTPS in production
- ✅ Set up proper SSL certificates
- ✅ Configure rate limiting
- ✅ Monitor application logs

---

## **Step 6: Production Checklist**

### **Before Going Live:**
- [ ] Email credentials configured in `.env`
- [ ] `NODE_ENV=production` set
- [ ] Email sending tested successfully
- [ ] OTP verification working
- [ ] Database backups configured
- [ ] SSL certificates installed
- [ ] Monitoring set up

### **Testing Commands:**
```bash
# Test email sending
curl -X POST http://localhost:3001/api/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@iitk.ac.in"}'

# Check backend logs
docker-compose logs backend --tail=10

# Test complete flow
# 1. Visit http://localhost:3000
# 2. Fill form and send OTP
# 3. Check email for OTP
# 4. Verify OTP and complete submission
```

---

## **Quick Setup Commands**

```bash
# 1. Create .env file
cat > .env << 'EOF'
# Database Configuration
DB_USER=portal_user
DB_HOST=postgres
DB_DATABASE=image_collection_db
DB_PASSWORD=portal_password
DB_PORT=5432

# Email Configuration (FILL THESE IN)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your.email@gmail.com
EMAIL_PASS=your_app_password

# Server Configuration
NODE_ENV=production
PORT=3001

# Frontend Configuration
NEXT_PUBLIC_API_URL=http://localhost:3001/api
EOF

# 2. Update docker-compose.yml for production
sed -i 's/NODE_ENV=development/NODE_ENV=production/' docker-compose.yml

# 3. Restart services
docker-compose down
docker-compose up -d

# 4. Test email
curl -X POST http://localhost:3001/api/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@iitk.ac.in"}'
```

---

**🎯 Once configured, your application will send real OTP emails to users!** 