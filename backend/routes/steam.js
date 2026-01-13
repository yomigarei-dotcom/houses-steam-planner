const express = require('express');
const { authenticateToken } = require('./auth');
const steamApi = require('../services/steamApi');
const db = require('../db');

const router = express.Router();

// Get user's game library
router.get('/games', authenticateToken, async (req, res) => {
    try {
        const user = await db.getOne('SELECT steam_id FROM users WHERE id = $1', [req.user.userId]);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        const games = await steamApi.getOwnedGames(user.steam_id);

        // Get local progress data
        const localProgress = await db.getMany(
            'SELECT * FROM user_games WHERE user_id = $1',
            [req.user.userId]
        );
        const progressMap = new Map(localProgress.map(p => [p.app_id, p]));

        // Merge Steam data with local progress
        const enrichedGames = games.map(game => {
            const progress = progressMap.get(game.appid);
            return {
                appId: game.appid,
                name: game.name,
                iconUrl: game.img_icon_url
                    ? `https://media.steampowered.com/steamcommunity/public/images/apps/${game.appid}/${game.img_icon_url}.jpg`
                    : null,
                logoUrl: game.img_logo_url
                    ? `https://media.steampowered.com/steamcommunity/public/images/apps/${game.appid}/${game.img_logo_url}.jpg`
                    : null,
                headerUrl: `https://steamcdn-a.akamaihd.net/steam/apps/${game.appid}/header.jpg`,
                playtimeForever: game.playtime_forever || 0,
                playtimeRecent: game.playtime_2weeks || 0,
                achievementsUnlocked: progress?.achievements_unlocked || 0,
                achievementsTotal: progress?.achievements_total || 0,
                completionPercentage: progress?.completion_percentage || 0,
                isComplete: progress?.completion_percentage === 100,
                lastPlayed: game.rtime_last_played
                    ? new Date(game.rtime_last_played * 1000)
                    : null
            };
        });

        // Sort by completion % desc, then by name
        enrichedGames.sort((a, b) => {
            if (b.completionPercentage !== a.completionPercentage) {
                return b.completionPercentage - a.completionPercentage;
            }
            return a.name.localeCompare(b.name);
        });

        res.json({
            totalGames: enrichedGames.length,
            games: enrichedGames
        });
    } catch (error) {
        console.error('Error fetching games:', error);
        res.status(500).json({ error: 'Failed to fetch games' });
    }
});

// Get achievements for a specific game
router.get('/games/:appId/achievements', authenticateToken, async (req, res) => {
    try {
        const { appId } = req.params;
        const user = await db.getOne('SELECT steam_id FROM users WHERE id = $1', [req.user.userId]);

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        const data = await steamApi.getFullAchievementData(user.steam_id, appId);

        // Update local cache
        await updateGameProgress(req.user.userId, appId, data);

        res.json(data);
    } catch (error) {
        console.error(`Error fetching achievements for ${req.params.appId}:`, error);
        res.status(500).json({ error: 'Failed to fetch achievements' });
    }
});

// Sync user's library and achievements
router.post('/sync', authenticateToken, async (req, res) => {
    try {
        const user = await db.getOne('SELECT steam_id FROM users WHERE id = $1', [req.user.userId]);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Clear cache to get fresh data
        steamApi.clearUserCache(user.steam_id);

        // Get all games
        const games = await steamApi.getOwnedGames(user.steam_id);

        let synced = 0;
        let completed = 0;
        const errors = [];

        // Sync each game (with rate limiting)
        for (const game of games) {
            try {
                // Cache game info
                await db.query(`
          INSERT INTO games (app_id, name, img_icon_url, img_logo_url)
          VALUES ($1, $2, $3, $4)
          ON CONFLICT (app_id) DO UPDATE SET
            name = EXCLUDED.name,
            img_icon_url = EXCLUDED.img_icon_url,
            img_logo_url = EXCLUDED.img_logo_url,
            cached_at = CURRENT_TIMESTAMP
        `, [game.appid, game.name, game.img_icon_url, game.img_logo_url]);

                // Get achievement data
                const achData = await steamApi.getFullAchievementData(user.steam_id, game.appid);

                if (achData.stats.total > 0) {
                    await updateGameProgress(req.user.userId, game.appid, achData);
                    synced++;

                    if (achData.stats.isComplete) {
                        completed++;
                    }
                }

                // Small delay to avoid rate limiting
                await new Promise(resolve => setTimeout(resolve, 100));
            } catch (err) {
                errors.push({ appId: game.appid, error: err.message });
            }
        }

        res.json({
            success: true,
            totalGames: games.length,
            gamesWithAchievements: synced,
            completedGames: completed,
            errors: errors.length > 0 ? errors : undefined
        });
    } catch (error) {
        console.error('Error syncing library:', error);
        res.status(500).json({ error: 'Failed to sync library' });
    }
});

// Helper: Update game progress in database
async function updateGameProgress(userId, appId, data) {
    const stats = data.stats;

    // Find first and last achievement dates
    const unlockedAchievements = data.achievements.filter(a => a.unlocked && a.unlockTime);
    const sortedByDate = unlockedAchievements.sort((a, b) => a.unlockTime - b.unlockTime);
    const firstDate = sortedByDate[0]?.unlockTime || null;
    const lastDate = sortedByDate[sortedByDate.length - 1]?.unlockTime || null;

    await db.query(`
    INSERT INTO user_games (user_id, app_id, achievements_unlocked, achievements_total, 
      completion_percentage, first_achievement_date, last_achievement_date, 
      completed_at, synced_at)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CURRENT_TIMESTAMP)
    ON CONFLICT (user_id, app_id) DO UPDATE SET
      achievements_unlocked = EXCLUDED.achievements_unlocked,
      achievements_total = EXCLUDED.achievements_total,
      completion_percentage = EXCLUDED.completion_percentage,
      first_achievement_date = COALESCE(user_games.first_achievement_date, EXCLUDED.first_achievement_date),
      last_achievement_date = EXCLUDED.last_achievement_date,
      completed_at = CASE 
        WHEN EXCLUDED.completion_percentage = 100 AND user_games.completed_at IS NULL 
        THEN CURRENT_TIMESTAMP 
        ELSE user_games.completed_at 
      END,
      synced_at = CURRENT_TIMESTAMP
  `, [
        userId,
        appId,
        stats.unlocked,
        stats.total,
        stats.completionPercentage,
        firstDate,
        lastDate,
        stats.isComplete ? new Date() : null
    ]);

    // Store individual achievements
    for (const ach of data.achievements) {
        await db.query(`
      INSERT INTO user_achievements (user_id, app_id, api_name, unlocked, unlock_time, synced_at)
      VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)
      ON CONFLICT (user_id, app_id, api_name) DO UPDATE SET
        unlocked = EXCLUDED.unlocked,
        unlock_time = EXCLUDED.unlock_time,
        synced_at = CURRENT_TIMESTAMP
    `, [userId, appId, ach.apiName, ach.unlocked, ach.unlockTime]);
    }

    // Update games table with achievement count
    await db.query(
        'UPDATE games SET total_achievements = $1 WHERE app_id = $2',
        [stats.total, appId]
    );
}

module.exports = router;
