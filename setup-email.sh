#!/bin/bash

# Email Setup Script for Image Collection Portal
# This script helps you configure email credentials for production

echo "📧 Email Setup for Image Collection Portal"
echo "=========================================="
echo ""

# Check if .env file exists
if [ -f ".env" ]; then
    echo "⚠️  .env file already exists. Backing up to .env.backup"
    cp .env .env.backup
fi

echo "🔧 Creating .env file with email configuration..."
echo ""

# Create .env file
cat > .env << 'EOF'
# Database Configuration
DB_USER=portal_user
DB_HOST=postgres
DB_DATABASE=image_collection_db
DB_PASSWORD=portal_password
DB_PORT=5432

# Email Configuration (FILL THESE IN BELOW)
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

echo "✅ .env file created successfully!"
echo ""
echo "📝 Next Steps:"
echo "1. Edit the .env file and fill in your email credentials"
echo "2. Run: nano .env (or your preferred editor)"
echo "3. Update EMAIL_USER and EMAIL_PASS with your actual credentials"
echo ""
echo "🔗 For detailed setup instructions, see: EMAIL_SETUP.md"
echo ""
echo "🚀 After updating credentials, restart the application:"
echo "   docker-compose down && docker-compose up -d"
echo ""
echo "🧪 Test email sending:"
echo "   curl -X POST http://localhost:3001/api/send-otp \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"email\":\"test@iitk.ac.in\"}'" 