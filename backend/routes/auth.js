const express = require('express');
const passport = require('passport');
const SteamStrategy = require('passport-steam').Strategy;
const jwt = require('jsonwebtoken');
const db = require('../db');

const router = express.Router();

// Configure Passport Steam Strategy
passport.use(new SteamStrategy({
    returnURL: process.env.STEAM_RETURN_URL || 'http://localhost:3000/auth/steam/callback',
    realm: process.env.STEAM_REALM || 'http://localhost:3000/',
    apiKey: process.env.STEAM_API_KEY
},
    async (identifier, profile, done) => {
        try {
            const steamId = profile.id;
            const username = profile.displayName;
            const avatarUrl = profile.photos[2]?.value || profile.photos[0]?.value;
            const profileUrl = profile._json.profileurl;

            // Upsert user
            const result = await db.query(`
        INSERT INTO users (steam_id, username, avatar_url, profile_url)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (steam_id) 
        DO UPDATE SET 
          username = EXCLUDED.username,
          avatar_url = EXCLUDED.avatar_url,
          profile_url = EXCLUDED.profile_url,
          updated_at = CURRENT_TIMESTAMP
        RETURNING *
      `, [steamId, username, avatarUrl, profileUrl]);

            return done(null, result.rows[0]);
        } catch (error) {
            return done(error, null);
        }
    }
));

passport.serializeUser((user, done) => {
    done(null, user.id);
});

passport.deserializeUser(async (id, done) => {
    try {
        const user = await db.getOne('SELECT * FROM users WHERE id = $1', [id]);
        done(null, user);
    } catch (error) {
        done(error, null);
    }
});

// Generate JWT token
function generateToken(user) {
    return jwt.sign(
        {
            userId: user.id,
            steamId: user.steam_id,
            username: user.username
        },
        process.env.JWT_SECRET || 'steamplanner-secret',
        { expiresIn: '7d' }
    );
}

// Middleware to verify JWT
function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'No token provided' });
    }

    jwt.verify(token, process.env.JWT_SECRET || 'steamplanner-secret', (err, decoded) => {
        if (err) {
            return res.status(403).json({ error: 'Invalid token' });
        }
        req.user = decoded;
        next();
    });
}

// Steam login initiation
router.get('/steam', passport.authenticate('steam'));

// Steam callback
router.get('/steam/callback',
    passport.authenticate('steam', { failureRedirect: '/auth/failure' }),
    (req, res) => {
        const token = generateToken(req.user);

        // Check if mobile app (redirect with custom scheme)
        const isMobile = req.query.mobile === 'true';

        if (isMobile) {
            // Redirect to mobile app with token
            res.redirect(`${process.env.MOBILE_SCHEME || 'steamplanner://'}auth?token=${token}`);
        } else {
            // Web response with token
            res.json({
                success: true,
                token,
                user: {
                    id: req.user.id,
                    steamId: req.user.steam_id,
                    username: req.user.username,
                    avatarUrl: req.user.avatar_url,
                    houseId: req.user.house_id,
                    generalPoints: req.user.general_points
                }
            });
        }
    }
);

// Mobile login - returns URL to open in browser
router.get('/steam/mobile', (req, res) => {
    const loginUrl = `${process.env.STEAM_REALM || 'http://localhost:3000'}/auth/steam?mobile=true`;
    res.json({ loginUrl });
});

// Get current user
router.get('/me', authenticateToken, async (req, res) => {
    try {
        const user = await db.getOne(`
      SELECT u.*, h.name as house_name, h.archetype as house_archetype, 
             h.color_primary as house_color_primary, h.color_secondary as house_color_secondary
      FROM users u
      LEFT JOIN houses h ON u.house_id = h.id
      WHERE u.id = $1
    `, [req.user.userId]);

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.json({
            id: user.id,
            steamId: user.steam_id,
            username: user.username,
            avatarUrl: user.avatar_url,
            profileUrl: user.profile_url,
            houseId: user.house_id,
            houseName: user.house_name,
            houseArchetype: user.house_archetype,
            houseColorPrimary: user.house_color_primary,
            houseColorSecondary: user.house_color_secondary,
            generalPoints: user.general_points,
            startDate: user.start_date
        });
    } catch (error) {
        console.error('Error fetching user:', error);
        res.status(500).json({ error: 'Failed to fetch user' });
    }
});

// Logout
router.post('/logout', authenticateToken, (req, res) => {
    req.logout(() => {
        res.json({ success: true });
    });
});

// Auth failure
router.get('/failure', (req, res) => {
    res.status(401).json({ error: 'Authentication failed' });
});

module.exports = router;
module.exports.authenticateToken = authenticateToken;
