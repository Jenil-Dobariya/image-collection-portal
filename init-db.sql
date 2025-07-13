-- Initialize database for Image Collection Portal
-- This script runs automatically when PostgreSQL container starts

-- Create tables if they don't exist
CREATE TABLE IF NOT EXISTS students (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    age INT NOT NULL,
    contact_info TEXT UNIQUE NOT NULL,
    consent_given BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS student_images (
    id UUID PRIMARY KEY,
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    image_age INT NOT NULL,
    uploaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS otps (
    id SERIAL PRIMARY KEY,
    email TEXT NOT NULL,
    otp_hash TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_otps_email ON otps(email);
CREATE INDEX IF NOT EXISTS idx_students_contact_info ON students(contact_info);
CREATE INDEX IF NOT EXISTS idx_student_images_student_id ON student_images(student_id);

-- Create a health check function
CREATE OR REPLACE FUNCTION health_check()
RETURNS TEXT AS $$
BEGIN
    RETURN 'OK';
END;
$$ LANGUAGE plpgsql;

-- Grant permissions to the portal user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO portal_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO portal_user;
GRANT EXECUTE ON FUNCTION health_check() TO portal_user; 