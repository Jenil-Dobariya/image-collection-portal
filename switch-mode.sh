#!/bin/bash

# Mode Switching Script for Image Collection Portal
# Usage: ./switch-mode.sh [development|production]

MODE=${1:-development}

echo "🔄 Switching to $MODE mode..."
echo ""

# Update docker-compose.yml
if [ "$MODE" = "production" ]; then
    sed -i 's/NODE_ENV=development/NODE_ENV=production/' docker-compose.yml
    echo "✅ Switched to PRODUCTION mode"
    echo "📧 Real email sending will be enabled"
    echo "🔐 OTP verification will require real OTP from email"
elif [ "$MODE" = "development" ]; then
    sed -i 's/NODE_ENV=production/NODE_ENV=development/' docker-compose.yml
    echo "✅ Switched to DEVELOPMENT mode"
    echo "📧 Email sending will be bypassed"
    echo "🔐 Any OTP will be accepted for testing"
else
    echo "❌ Invalid mode. Use 'development' or 'production'"
    exit 1
fi

echo ""
echo "🔄 Restarting containers..."
docker-compose down
docker-compose up -d

echo ""
echo "✅ Application is now running in $MODE mode"
echo ""
echo "🧪 Test the mode:"
echo "   curl -X POST http://localhost:3001/api/send-otp \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"email\":\"test@iitk.ac.in\"}'"
echo ""
echo "🌐 Access the application: http://localhost:3000" 