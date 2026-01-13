const express = require('express');
const { authenticateToken } = require('./auth');
const db = require('../db');

const router = express.Router();

// Get all houses
router.get('/', async (req, res) => {
    try {
        const houses = await db.getMany(`
      SELECT h.*, 
        (SELECT COUNT(*) FROM users WHERE house_id = h.id) as member_count,
        (SELECT COALESCE(SUM(general_points), 0) FROM users WHERE house_id = h.id) as total_points
      FROM houses h
      ORDER BY h.id
    `);

        res.json({ houses });
    } catch (error) {
        console.error('Error fetching houses:', error);
        res.status(500).json({ error: 'Failed to fetch houses' });
    }
});

// Get house cup standings (all houses compared)
router.get('/cup', async (req, res) => {
    try {
        // General points standings
        const generalStandings = await db.getMany(`
      SELECT h.id, h.name, h.archetype, h.color_primary, h.color_secondary, h.icon,
        COUNT(u.id) as members,
        COALESCE(SUM(u.general_points), 0) as total_points
      FROM houses h
      LEFT JOIN users u ON h.id = u.house_id
      GROUP BY h.id
      ORDER BY total_points DESC
    `);

        // Season points standings
        const activeSeason = await db.getOne('SELECT id, name FROM seasons WHERE is_active = true LIMIT 1');

        let seasonStandings = [];
        if (activeSeason) {
            seasonStandings = await db.getMany(`
        SELECT h.id, h.name, h.archetype, h.color_primary, h.color_secondary, h.icon,
          COALESCE(hss.total_points, 0) as season_points,
          hss.rank
        FROM houses h
        LEFT JOIN house_season_standings hss ON h.id = hss.house_id AND hss.season_id = $1
        ORDER BY season_points DESC
      `, [activeSeason.id]);
        }

        res.json({
            general: {
                standings: generalStandings.map((h, i) => ({ ...h, rank: i + 1 }))
            },
            season: activeSeason ? {
                seasonId: activeSeason.id,
                seasonName: activeSeason.name,
                standings: seasonStandings.map((h, i) => ({ ...h, rank: i + 1 }))
            } : null
        });
    } catch (error) {
        console.error('Error fetching house cup:', error);
        res.status(500).json({ error: 'Failed to fetch house cup standings' });
    }
});

// Get quiz questions
router.get('/quiz', async (req, res) => {
    try {
        const questions = await db.getMany(`
      SELECT id, question, options, order_index
      FROM quiz_questions
      ORDER BY order_index
    `);

        res.json({ questions });
    } catch (error) {
        console.error('Error fetching quiz:', error);
        res.status(500).json({ error: 'Failed to fetch quiz' });
    }
});

// Submit quiz answers and get assigned house
router.post('/quiz/submit', authenticateToken, async (req, res) => {
    try {
        const { answers } = req.body; // Array of { questionId, selectedHouse }

        if (!answers || !Array.isArray(answers)) {
            return res.status(400).json({ error: 'Invalid answers format' });
        }

        // Count votes per house
        const houseCounts = {
            achiever: 0,
            explorer: 0,
            socializer: 0,
            killer: 0
        };

        for (const answer of answers) {
            if (houseCounts.hasOwnProperty(answer.selectedHouse)) {
                houseCounts[answer.selectedHouse]++;
            }
        }

        // Find winning house
        const sortedHouses = Object.entries(houseCounts).sort((a, b) => b[1] - a[1]);
        const winningHouseKey = sortedHouses[0][0];

        // Map to house ID
        const houseMapping = {
            achiever: 1,
            explorer: 2,
            socializer: 3,
            killer: 4
        };
        const houseId = houseMapping[winningHouseKey];

        // Update user's house
        await db.query(
            'UPDATE users SET house_id = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
            [houseId, req.user.userId]
        );

        // Get house details
        const house = await db.getOne('SELECT * FROM houses WHERE id = $1', [houseId]);

        res.json({
            success: true,
            house: {
                id: house.id,
                name: house.name,
                archetype: house.archetype,
                description: house.description,
                colorPrimary: house.color_primary,
                colorSecondary: house.color_secondary,
                icon: house.icon
            },
            breakdown: houseCounts,
            message: `Welcome to ${house.name}, the ${house.archetype}! 🎉`
        });
    } catch (error) {
        console.error('Error submitting quiz:', error);
        res.status(500).json({ error: 'Failed to submit quiz' });
    }
});

// Manually set house (skip quiz)
router.post('/join/:houseId', authenticateToken, async (req, res) => {
    try {
        const houseId = parseInt(req.params.houseId);

        if (houseId < 1 || houseId > 4) {
            return res.status(400).json({ error: 'Invalid house ID' });
        }

        await db.query(
            'UPDATE users SET house_id = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
            [houseId, req.user.userId]
        );

        const house = await db.getOne('SELECT * FROM houses WHERE id = $1', [houseId]);

        res.json({
            success: true,
            house: {
                id: house.id,
                name: house.name,
                archetype: house.archetype,
                colorPrimary: house.color_primary,
                colorSecondary: house.color_secondary
            }
        });
    } catch (error) {
        console.error('Error joining house:', error);
        res.status(500).json({ error: 'Failed to join house' });
    }
});

// Get house members (leaderboard within house)
router.get('/:houseId/members', async (req, res) => {
    try {
        const { houseId } = req.params;

        const members = await db.getMany(`
      SELECT u.id, u.username, u.avatar_url, u.general_points,
        (SELECT COUNT(*) FROM user_medals WHERE user_id = u.id) as total_medals,
        (SELECT COUNT(DISTINCT app_id) FROM user_games WHERE user_id = u.id AND completion_percentage = 100) as completed_games
      FROM users u
      WHERE u.house_id = $1
      ORDER BY u.general_points DESC
      LIMIT 50
    `, [houseId]);

        res.json({
            members: members.map((m, i) => ({ ...m, rank: i + 1 }))
        });
    } catch (error) {
        console.error('Error fetching house members:', error);
        res.status(500).json({ error: 'Failed to fetch house members' });
    }
});

module.exports = router;
