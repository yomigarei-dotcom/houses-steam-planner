require('dotenv').config();
const express = require('express');
const cors = require('cors');
const session = require('express-session');
const passport = require('passport');

// Import routes
const authRoutes = require('./routes/auth');
const steamRoutes = require('./routes/steam');
const medalsRoutes = require('./routes/medals');
const housesRoutes = require('./routes/houses');
const seasonsRoutes = require('./routes/seasons');

// Import database
const db = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors({
    origin: [process.env.FRONTEND_URL, 'http://localhost:3000'],
    credentials: true
}));
app.use(express.json());
app.use(session({
    secret: process.env.JWT_SECRET || 'steamplanner-secret',
    resave: false,
    saveUninitialized: false,
    cookie: {
        secure: process.env.NODE_ENV === 'production',
        maxAge: 24 * 60 * 60 * 1000 // 24 hours
    }
}));

// Passport initialization
app.use(passport.initialize());
app.use(passport.session());

// Health check
app.get('/api/health', (req, res) => {
    res.json({
        status: 'ok',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        name: 'SteamPlanner API'
    });
});

// Routes
app.use('/auth', authRoutes);
app.use('/api/steam', steamRoutes);
app.use('/api/medals', medalsRoutes);
app.use('/api/houses', housesRoutes);
app.use('/api/seasons', seasonsRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Error:', err.message);
    res.status(err.status || 500).json({
        error: err.message || 'Internal Server Error'
    });
});

// Initialize database and start server
async function startServer() {
    try {
        await db.initialize();
        console.log('Database initialized');

        app.listen(PORT, () => {
            console.log(`🎮 SteamPlanner API running on port ${PORT}`);
            console.log(`   Health: http://localhost:${PORT}/api/health`);
        });
    } catch (error) {
        console.error('Failed to start server:', error);
        process.exit(1);
    }
}

startServer();
