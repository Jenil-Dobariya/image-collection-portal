const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');
const nodemailer = require('nodemailer');
const bcrypt = require('bcrypt');
const { pool } = require('../db');

const router = express.Router();
const saltRounds = 10;

// --- Nodemailer Setup ---
const transporter = nodemailer.createTransport({
    host: process.env.EMAIL_HOST,
    port: process.env.EMAIL_PORT,
    secure: false, // true for 465, false for other ports
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});

// --- Multer Storage Configuration ---
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // We need a unique ID before we know the destination, so we set it on the request
    if (!req.studentId) {
        req.studentId = uuidv4();
    }
    const studentId = req.studentId;
    let dir;
    if (file.fieldname === 'consentForm') {
        dir = path.join('/data/consent_form/', studentId);
    } else {
        dir = path.join('/data/student_uploads/', studentId);
    }
    fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    if (file.fieldname === 'consentForm') {
      cb(null, '__consent_form.pdf');
    } else {
      // Use a counter on the request to name image files sequentially
      req.imageIndex = (req.imageIndex || 0) + 1;
      const extension = path.extname(file.originalname);
      cb(null, `${req.imageIndex}${extension}`);
    }
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB per file
  fileFilter: (req, file, cb) => {
    const isImage = file.mimetype.startsWith('image/');
    const isPdf = file.mimetype === 'application/pdf';
    if ((file.fieldname === 'images' && isImage) || (file.fieldname === 'consentForm' && isPdf)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type.'), false);
    }
  },
});

// --- API Endpoints ---

// 1. Send OTP
router.post('/send-otp', async (req, res) => {
    const { email } = req.body;
    if (!email || !email.endsWith('@iitk.ac.in')) {
        return res.status(400).json({ message: 'A valid IITK email is required.' });
    }

    const client = await pool.connect();

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otp_hash = await bcrypt.hash(otp, saltRounds);
    const expires_at = new Date(Date.now() + 10 * 60 * 1000); // Expires in 10 minutes

    try {
        await client.query('BEGIN');

        await client.query(
            'INSERT INTO otps (email, otp_hash, expires_at) VALUES ($1, $2, $3)',
            [email, otp_hash, expires_at]
        );

        await transporter.sendMail({
            from: `${process.env.EMAIL_USER}>`,
            replyTo: `${process.env.EMAIL_USER}`,
            to: email,
            subject: '[Smart Search] Verify email for Image Collection Portal',
            html: `<b>Your OTP to verify email for consent form on image collection portal is: ${otp}</b><p>It will expire in 10 minutes.</p><br><p>This is an automated message. Please do not reply to this email.</p>`,
        });

        await client.query('COMMIT');
        res.status(200).json({ message: 'OTP sent successfully.' });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error sending OTP:', error);

        res.status(500).json({ message: 'Failed to send OTP.' });
    }
});

// 2. Verify OTP
router.post('/verify-otp', async (req, res) => {
    const { email, otp } = req.body;
    if (!email || !otp) {
        return res.status(400).json({ message: 'Email and OTP are required.' });
    }

    try {
        const result = await pool.query(
            'SELECT * FROM otps WHERE email = $1 AND expires_at > NOW() ORDER BY created_at DESC LIMIT 1',
            [email]
        );

        if (result.rows.length === 0) {
            return res.status(400).json({ message: 'OTP Expired, Please try again.' });
        }

        const validOtp = await bcrypt.compare(otp, result.rows[0].otp_hash);
        if (!validOtp) {
            return res.status(400).json({ message: 'Invalid OTP, Please enter correct OTP.' });
        }
        
        // Clean up used OTP
        await pool.query('DELETE FROM otps WHERE email = $1', [email]);

        res.status(200).json({ message: 'Email verified successfully.' });
    } catch (error) {
        console.error('Error verifying OTP:', error);
        res.status(500).json({ message: 'Internal server error.' });
    }
});


// 3. Submit Form Data and Images
const submissionFields = [{ name: 'images', maxCount: 10 }, { name: 'consentForm', maxCount: 1 }];
router.post('/submit', upload.fields(submissionFields), async (req, res) => {
    const { name, age, email, consentGiven, imageAges } = req.body;
    const images = req.files['images'];
    const consentForm = req.files['consentForm'] ? req.files['consentForm'][0] : null;
    
    // --- Validation ---
    if (!name || !age || !email || consentGiven !== 'true' || !images || images.length === 0 || !consentForm) {
        return res.status(400).json({ message: 'Missing required form data.' });
    }

    const client = await pool.connect();
    const studentId = req.studentId; // Get the UUID generated by Multer

    try {
        await client.query('BEGIN');

        // Insert into students table
        const studentInsertQuery = `
            INSERT INTO students (id, name, age, contact_info, consent_given)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id;
        `;
        const studentResult = await client.query(studentInsertQuery, [studentId, name, age, email, true]);
        const dbStudentId = studentResult.rows[0].id;

        // Insert into student_images table
        const imageInsertQuery = `
            INSERT INTO student_images (id, student_id, file_path, image_age)
            VALUES ($1, $2, $3, $4);
        `;
        const ages = JSON.parse(imageAges);
        for (let i = 0; i < images.length; i++) {
            const image = images[i];
            const relativePath = path.relative('/data', image.path);
            await client.query(imageInsertQuery, [uuidv4(), dbStudentId, relativePath, ages[i]]);
        }
        
        await client.query('COMMIT');
        res.status(201).json({ message: 'Submission successful!', studentId: dbStudentId });

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Submission Error:', error);
        
        // Cleanup failed upload files
        fs.rm(path.join('/data/student_uploads/', studentId), { recursive: true, force: true }, () => {});
        fs.rm(path.join('/data/consent_form/', studentId), { recursive: true, force: true }, () => {});

        res.status(500).json({ message: 'An error occurred during submission.' });
    } finally {
        client.release();
    }
});

module.exports = router;