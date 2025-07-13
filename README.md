# Image Collection Portal

A comprehensive web application for collecting student images with consent management, email verification, and secure data storage. This portal is designed for academic research purposes with a focus on privacy and data protection.

## 🏗️ Architecture

The application follows a **client-server architecture** with separate frontend and backend components:

### Frontend (Next.js 15 + React 19)
- **Framework**: Next.js 15 with React 19
- **Styling**: CSS Modules with modern design
- **Key Features**:
  - Multi-step form with consent management
  - Email verification via OTP
  - Image upload with age metadata
  - PDF consent form generation
  - Responsive design

### Backend (Node.js + Express)
- **Runtime**: Node.js with Express.js
- **Database**: PostgreSQL with UUID primary keys
- **Key Features**:
  - RESTful API endpoints
  - Email service integration (Nodemailer)
  - File upload handling (Multer)
  - Password hashing (bcrypt)
  - CORS configuration

## 📋 Features

### 🔐 Security & Privacy
- **Email Verification**: OTP-based verification for IITK email addresses
- **Consent Management**: Mandatory consent form with PDF generation
- **Data Encryption**: Password hashing for OTP storage
- **File Validation**: Image type and size restrictions
- **CORS Protection**: Configured for frontend-backend communication

### 📸 Image Collection
- **Multi-Image Upload**: Up to 10 images per submission
- **Age Metadata**: Each image includes age information
- **File Validation**: JPG/PNG formats, 5MB size limit
- **Preview System**: Real-time image previews

### 📊 Data Management
- **Structured Storage**: PostgreSQL with normalized tables
- **Audit Trail**: Timestamps for all submissions
- **Unique Identifiers**: UUID-based primary keys
- **Cascade Deletion**: Automatic cleanup of related data

## 🚀 Quick Start

### Option 1: Docker (Recommended)

**Prerequisites:**
- **Docker** (v20.10 or higher)
- **Docker Compose** (v2.0 or higher)

**Quick Setup:**
```bash
# Clone the repository
git clone <repository-url>
cd image-collection-portal

# Run the startup script
./start.sh

# Or manually:
docker-compose up -d
```

**Access the application:**
- Frontend: http://localhost:3000
- Backend API: http://localhost:3001
- Health Check: http://localhost:3001/api/health

### Option 2: Manual Setup

**Prerequisites:**
- **Node.js** (v18 or higher)
- **PostgreSQL** (v12 or higher)
- **Git**

### 1. Clone the Repository
```bash
git clone <repository-url>
cd image-collection-portal
```

### 2. Backend Setup

#### Install Dependencies
```bash
cd backend
npm install
```

#### Environment Configuration
Create a `.env` file in the `backend` directory:
```env
# Database Configuration
DB_USER=your_db_user
DB_HOST=localhost
DB_DATABASE=image_collection_db
DB_PASSWORD=your_db_password
DB_PORT=5432

# Email Configuration (for OTP)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_app_password

# Server Configuration
PORT=3001
```

#### Database Setup
1. Create a PostgreSQL database:
```sql
CREATE DATABASE image_collection_db;
```

2. The application will automatically create required tables on startup.

#### Start Backend Server
```bash
# Development mode (with auto-restart)
npm run dev

# Production mode
npm start
```

The backend will be available at `http://localhost:3001`

### 3. Frontend Setup

#### Install Dependencies
```bash
cd ../frontend
npm install
```

#### Start Frontend Development Server
```bash
npm run dev
```

The frontend will be available at `http://localhost:3000`

## 📁 Project Structure

```
image-collection-portal/
├── backend/
│   ├── Dockerfile         # Backend container configuration
│   ├── db.js              # Database connection and table creation
│   ├── server.js          # Express server setup
│   ├── routes/
│   │   └── api.js        # API endpoints
│   └── package.json
├── frontend/
│   ├── Dockerfile         # Frontend container configuration
│   ├── src/
│   │   └── app/
│   │       ├── page.js    # Main application component
│   │       ├── layout.js  # Root layout
│   │       ├── globals.css
│   │       └── page.module.css
│   └── package.json
├── docker-compose.yml     # Main Docker Compose configuration
├── docker-compose.prod.yml # Production Docker Compose override
├── start.sh              # Automated startup script
├── backup.sh             # Backup and restore script
├── init-db.sql          # Database initialization script
├── nginx.conf           # Nginx reverse proxy configuration
├── .dockerignore        # Docker ignore files
└── README.md
```

## 🔌 API Endpoints

### Authentication
- `POST /api/send-otp` - Send OTP to email
- `POST /api/verify-otp` - Verify OTP and authenticate

### Data Submission
- `POST /api/submit` - Submit student data and images

## 🗄️ Database Schema

### Students Table
```sql
CREATE TABLE students (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  age INT NOT NULL,
  contact_info TEXT UNIQUE NOT NULL,
  consent_given BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
```

### Student Images Table
```sql
CREATE TABLE student_images (
  id UUID PRIMARY KEY,
  student_id UUID REFERENCES students(id) ON DELETE CASCADE,
  file_path TEXT NOT NULL,
  image_age INT NOT NULL,
  uploaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
```

### OTP Table
```sql
CREATE TABLE otps (
  id SERIAL PRIMARY KEY,
  email TEXT NOT NULL,
  otp_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
```

## 🔧 Configuration

### Email Service
The application uses Nodemailer for OTP delivery. Configure your email provider in the `.env` file:

- **Gmail**: Use App Password for authentication
- **SMTP**: Configure host, port, and credentials
- **Security**: Enable 2FA and generate app-specific passwords

### File Storage
- **Upload Directory**: `/data/student_uploads/` and `/data/consent_form/`
- **File Organization**: UUID-based folder structure
- **Access Control**: Static file serving for debugging

## 🛡️ Security Considerations

### Data Protection
- **Encryption**: OTP hashing with bcrypt
- **Validation**: Email domain restrictions (@iitk.ac.in)
- **File Limits**: 5MB per file, image formats only
- **CORS**: Configured for specific origins

### Privacy Compliance
- **Consent Management**: Mandatory consent form
- **Data Minimization**: Only necessary fields collected
- **Audit Trail**: Timestamp tracking for all operations
- **Secure Deletion**: Cascade deletion for data cleanup

## 🚀 Deployment

### Docker Production Deployment

```bash
# Build and start production stack
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Monitor production logs
docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f

# Create backup
./backup.sh

# Restore from backup
./backup.sh restore backups/complete_backup_YYYYMMDD_HHMMSS.tar.gz
```

### Production Considerations
1. **Environment Variables**: Secure all sensitive data
2. **Database**: Use production PostgreSQL instance
3. **File Storage**: Configure secure file serving
4. **HTTPS**: Enable SSL/TLS encryption
5. **Monitoring**: Implement logging and error tracking
6. **Backups**: Regular automated backups
7. **Resource Limits**: Configure memory and CPU limits
8. **Security**: Use non-root users, network isolation

### Manual Deployment
```dockerfile
# Backend Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3001
CMD ["npm", "start"]
```

## 🧪 Development

### Docker Development

```bash
# Start all services
./start.sh

# View logs
docker-compose logs -f

# Restart specific service
docker-compose restart backend

# Access container shell
docker-compose exec backend sh
docker-compose exec postgres psql -U portal_user -d image_collection_db

# Stop all services
docker-compose down
```

### Manual Development

#### Available Scripts

#### Backend
```bash
npm run dev    # Start with nodemon
npm start      # Start production server
npm test       # Run tests (placeholder)
```

#### Frontend
```bash
npm run dev    # Start development server
npm run build  # Build for production
npm start      # Start production server
npm run lint   # Run ESLint
```

### Development Workflow
1. Start PostgreSQL database
2. Configure environment variables
3. Start backend server (`npm run dev`)
4. Start frontend server (`npm run dev`)
5. Access application at `http://localhost:3000`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the ISC License.

## 🆘 Support

For issues and questions:
1. Check the documentation
2. Review existing issues
3. Create a new issue with detailed information

---

**Note**: This application is designed for academic research purposes. Ensure compliance with institutional policies and data protection regulations. 