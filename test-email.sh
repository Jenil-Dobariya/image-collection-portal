#!/bin/bash

# Email Test Script for Image Collection Portal
# This script tests your email configuration

echo "🧪 Testing Email Configuration"
echo "=============================="
echo ""

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found!"
    echo "Run: ./setup-email.sh first"
    exit 1
fi

# Check if containers are running
if ! docker-compose ps | grep -q "image-portal-backend"; then
    echo "❌ Backend container is not running!"
    echo "Run: docker-compose up -d"
    exit 1
fi

echo "✅ Backend container is running"
echo ""

# Test email sending
echo "📧 Testing email sending..."
echo "Sending test OTP to: test@iitk.ac.in"
echo ""

response=$(curl -s -X POST http://localhost:3001/api/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@iitk.ac.in"}')

echo "Response: $response"
echo ""

# Check response
if echo "$response" | grep -q "OTP sent successfully"; then
    echo "✅ Email sending successful!"
    echo ""
    echo "📝 Check the backend logs for details:"
    echo "   docker-compose logs backend --tail=10"
    echo ""
    echo "📧 If you see 'Email sending failed' in logs, check your credentials in .env"
else
    echo "❌ Email sending failed!"
    echo ""
    echo "🔍 Troubleshooting:"
    echo "1. Check your email credentials in .env"
    echo "2. Ensure you're using App Password (not regular password)"
    echo "3. Verify 2-Factor Authentication is enabled"
    echo "4. Check backend logs: docker-compose logs backend --tail=20"
fi

echo ""
echo "🔗 For detailed setup instructions, see: EMAIL_SETUP.md" 