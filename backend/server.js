require('dotenv').config();
const express = require('express');
const cors = require('cors');
const apiRoutes = require('./routes/api');
const { createTables } = require('./db');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3001;

// --- Middleware ---
app.use(cors({ origin: 'http://localhost:3000' })); // Allow frontend access
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files for uploads (for internal access/debugging if needed)
// In production, Nginx would handle this more securely.
app.use('/uploads', express.static(path.join(__dirname, '/data/student_uploads')));

// --- Routes ---
app.use('/api', apiRoutes);

// --- Server Startup ---
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  // Initialize database tables on startup
  createTables();
});
