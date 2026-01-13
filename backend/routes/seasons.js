const express = require('express');
const { authenticateToken } = require('./auth');
const db = require('../db');

const router = express.Router();

// Get current active season
router.get('/current', async (req, res) => {
    try {
        const season = await db.getOne(`
      SELECT * FROM seasons WHERE is_active = true LIMIT 1
    `);

        if (!season) {
            return res.json({
                season: null,
                message: 'No active season'
            });
        }

        // Get days remaining
        const now = new Date();
        const endDate = new Date(season.end_date);
        const daysRemaining = Math.ceil((endDate - now) / (1000 * 60 * 60 * 24));

        res.json({
            season: {
                id: season.id,
                name: season.name,
                startDate: season.start_date,
                endDate: season.end_date,
                daysRemaining: Math.max(0, daysRemaining),
                isActive: season.is_active
            }
        });
    } catch (error) {
        console.error('Error fetching current season:', error);
        res.status(500).json({ error: 'Failed to fetch season' });
    }
});

// Get all seasons (history)
router.get('/all', async (req, res) => {
    try {
        const seasons = await db.getMany(`
      SELECT * FROM seasons ORDER BY start_date DESC
    `);

        res.json({ seasons });
    } catch (error) {
        console.error('Error fetching seasons:', error);
        res.status(500).json({ error: 'Failed to fetch seasons' });
    }
});

// Get leaderboard for current/specified season
router.get('/leaderboard', authenticateToken, async (req, res) => {
    try {
        const { seasonId } = req.query;

        let season;
        if (seasonId) {
            season = await db.getOne('SELECT * FROM seasons WHERE id = $1', [seasonId]);
        } else {
            season = await db.getOne('SELECT * FROM seasons WHERE is_active = true LIMIT 1');
        }

        if (!season) {
            return res.json({
                leaderboard: [],
                message: 'No season found'
            });
        }

        // User leaderboard
        const userLeaderboard = await db.getMany(`
      SELECT u.id, u.username, u.avatar_url, u.house_id, h.name as house_name,
        h.color_primary as house_color, sp.points as season_points
      FROM users u
      JOIN season_points sp ON u.id = sp.user_id AND sp.season_id = $1
      LEFT JOIN houses h ON u.house_id = h.id
      ORDER BY sp.points DESC
      LIMIT 100
    `, [season.id]);

        // House leaderboard
        const houseLeaderboard = await db.getMany(`
      SELECT h.id, h.name, h.archetype, h.color_primary, h.color_secondary,
        COALESCE(hss.total_points, 0) as points
      FROM houses h
      LEFT JOIN house_season_standings hss ON h.id = hss.house_id AND hss.season_id = $1
      ORDER BY points DESC
    `, [season.id]);

        // Get current user's position
        const userPosition = await db.getOne(`
      SELECT sp.points,
        (SELECT COUNT(*) + 1 FROM season_points WHERE season_id = $1 AND points > sp.points) as rank
      FROM season_points sp
      WHERE sp.user_id = $2 AND sp.season_id = $1
    `, [season.id, req.user.userId]);

        res.json({
            season: {
                id: season.id,
                name: season.name
            },
            users: userLeaderboard.map((u, i) => ({ ...u, rank: i + 1 })),
            houses: houseLeaderboard.map((h, i) => ({ ...h, rank: i + 1 })),
            currentUser: userPosition ? {
                rank: parseInt(userPosition.rank),
                points: userPosition.points
            } : null
        });
    } catch (error) {
        console.error('Error fetching leaderboard:', error);
        res.status(500).json({ error: 'Failed to fetch leaderboard' });
    }
});

// Get season challenges
router.get('/challenges', authenticateToken, async (req, res) => {
    try {
        const season = await db.getOne('SELECT id FROM seasons WHERE is_active = true LIMIT 1');

        if (!season) {
            return res.json({ challenges: [] });
        }

        // Get seasonal medal definitions as "challenges"
        const challenges = await db.getMany(`
      SELECT md.id, md.medal_key, md.name, md.description, md.icon, md.tier, md.points,
        md.conditions,
        CASE WHEN um.id IS NOT NULL THEN true ELSE false END as completed
      FROM medal_definitions md
      LEFT JOIN user_medals um ON md.id = um.medal_id AND um.user_id = $1
      WHERE md.is_seasonal = true AND md.season_id = $2
      ORDER BY md.points DESC
    `, [req.user.userId, season.id]);

        res.json({
            seasonId: season.id,
            challenges
        });
    } catch (error) {
        console.error('Error fetching challenges:', error);
        res.status(500).json({ error: 'Failed to fetch challenges' });
    }
});

// Create a new season (admin endpoint, could be protected later)
router.post('/create', async (req, res) => {
    try {
        const { name, startDate, endDate } = req.body;

        if (!name || !startDate || !endDate) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        // Deactivate current season
        await db.query('UPDATE seasons SET is_active = false WHERE is_active = true');

        // Create new season
        const result = await db.query(`
      INSERT INTO seasons (name, start_date, end_date, is_active)
      VALUES ($1, $2, $3, true)
      RETURNING *
    `, [name, startDate, endDate]);

        // Initialize house standings for new season
        await db.query(`
      INSERT INTO house_season_standings (house_id, season_id, total_points, rank)
      SELECT id, $1, 0, id FROM houses
    `, [result.rows[0].id]);

        res.json({
            success: true,
            season: result.rows[0]
        });
    } catch (error) {
        console.error('Error creating season:', error);
        res.status(500).json({ error: 'Failed to create season' });
    }
});

module.exports = router;
