const express = require('express');
const { authenticateToken } = require('./auth');
const medalEngine = require('../services/medalEngine');
const steamApi = require('../services/steamApi');
const db = require('../db');

const router = express.Router();

// Get user's medals
router.get('/', authenticateToken, async (req, res) => {
    try {
        const data = await medalEngine.getUserMedals(req.user.userId);
        res.json(data);
    } catch (error) {
        console.error('Error fetching medals:', error);
        res.status(500).json({ error: 'Failed to fetch medals' });
    }
});

// Evaluate medals for a specific game
router.post('/evaluate/:appId', authenticateToken, async (req, res) => {
    try {
        const { appId } = req.params;
        const user = await db.getOne('SELECT steam_id FROM users WHERE id = $1', [req.user.userId]);

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Get fresh achievement data
        const gameStats = await steamApi.getFullAchievementData(user.steam_id, appId);

        // Evaluate all medals
        const newMedals = await medalEngine.evaluateMedals(req.user.userId, appId, gameStats);

        res.json({
            gameName: gameStats.gameName,
            gameStats: gameStats.stats,
            newMedals,
            message: newMedals.length > 0
                ? `🏅 Congratulations! You earned ${newMedals.length} new medal(s)!`
                : 'No new medals earned for this game.'
        });
    } catch (error) {
        console.error('Error evaluating medals:', error);
        res.status(500).json({ error: 'Failed to evaluate medals' });
    }
});

// Get medal definitions (for display)
router.get('/definitions', async (req, res) => {
    try {
        const medals = await db.getMany(`
      SELECT medal_key, name, description, icon, tier, points, house_bonus, is_seasonal
      FROM medal_definitions
      ORDER BY is_seasonal, tier, points DESC
    `);

        res.json({ medals });
    } catch (error) {
        console.error('Error fetching medal definitions:', error);
        res.status(500).json({ error: 'Failed to fetch medal definitions' });
    }
});

// Evaluate all completed games for medals (bulk)
router.post('/evaluate-all', authenticateToken, async (req, res) => {
    try {
        const user = await db.getOne('SELECT steam_id FROM users WHERE id = $1', [req.user.userId]);

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Get all completed games
        const completedGames = await db.getMany(`
      SELECT app_id FROM user_games 
      WHERE user_id = $1 AND completion_percentage = 100
    `, [req.user.userId]);

        let totalNewMedals = 0;
        const allNewMedals = [];

        for (const game of completedGames) {
            try {
                const gameStats = await steamApi.getFullAchievementData(user.steam_id, game.app_id);
                const newMedals = await medalEngine.evaluateMedals(req.user.userId, game.app_id, gameStats);

                if (newMedals.length > 0) {
                    totalNewMedals += newMedals.length;
                    allNewMedals.push(...newMedals);
                }

                // Rate limiting
                await new Promise(resolve => setTimeout(resolve, 100));
            } catch (err) {
                console.error(`Error evaluating game ${game.app_id}:`, err.message);
            }
        }

        res.json({
            gamesEvaluated: completedGames.length,
            newMedalsEarned: totalNewMedals,
            medals: allNewMedals
        });
    } catch (error) {
        console.error('Error in bulk medal evaluation:', error);
        res.status(500).json({ error: 'Failed to evaluate medals' });
    }
});

module.exports = router;
