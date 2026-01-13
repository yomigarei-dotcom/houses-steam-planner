const db = require('../db');

class MedalEngine {

    // Evaluate all medals for a completed game
    async evaluateMedals(userId, appId, gameStats) {
        const results = [];

        // Get all active medal definitions
        const medals = await db.getMany(`
      SELECT * FROM medal_definitions 
      WHERE is_seasonal = false OR (is_seasonal = true AND season_id = (
        SELECT id FROM seasons WHERE is_active = true LIMIT 1
      ))
    `);

        for (const medal of medals) {
            const qualifies = await this.checkConditions(medal.conditions, userId, appId, gameStats);

            if (qualifies) {
                // Check if already has this medal for this game
                const existing = await db.getOne(
                    'SELECT id FROM user_medals WHERE user_id = $1 AND medal_id = $2 AND app_id = $3',
                    [userId, medal.id, appId]
                );

                if (!existing) {
                    // Award the medal
                    const gameName = gameStats.gameName || `Game ${appId}`;

                    await db.query(`
            INSERT INTO user_medals (user_id, medal_id, app_id, game_name, points_earned)
            VALUES ($1, $2, $3, $4, $5)
          `, [userId, medal.id, appId, gameName, medal.points]);

                    // Update user's general points
                    await db.query(
                        'UPDATE users SET general_points = general_points + $1 WHERE id = $2',
                        [medal.points, userId]
                    );

                    // If seasonal, also add to season points
                    if (medal.is_seasonal) {
                        await this.addSeasonPoints(userId, medal.points);
                    }

                    results.push({
                        medalId: medal.id,
                        medalKey: medal.medal_key,
                        name: medal.name,
                        description: medal.description,
                        icon: medal.icon,
                        tier: medal.tier,
                        points: medal.points,
                        gameName,
                        isNew: true
                    });
                }
            }
        }

        return results;
    }

    // Check medal conditions against game stats
    async checkConditions(conditions, userId, appId, gameStats) {
        if (!conditions || !conditions.rules) return false;

        const checkRule = async (rule) => {
            const value = await this.getFieldValue(rule.field, userId, appId, gameStats);

            switch (rule.operator) {
                case '==': return value === rule.value;
                case '!=': return value !== rule.value;
                case '<': return value < rule.value;
                case '<=': return value <= rule.value;
                case '>': return value > rule.value;
                case '>=': return value >= rule.value;
                default: return false;
            }
        };

        if (conditions.type === 'AND') {
            for (const rule of conditions.rules) {
                if (!(await checkRule(rule))) return false;
            }
            return true;
        } else if (conditions.type === 'OR') {
            for (const rule of conditions.rules) {
                if (await checkRule(rule)) return true;
            }
            return false;
        }

        return false;
    }

    // Get the value of a field for condition checking
    async getFieldValue(field, userId, appId, gameStats) {
        switch (field) {
            case 'completion_percentage':
                return gameStats.stats?.completionPercentage || 0;

            case 'average_rarity':
                return gameStats.stats?.averageRarity || 100;

            case 'completion_hours': {
                // Hours between first and last achievement
                const progress = await db.getOne(
                    'SELECT first_achievement_date, last_achievement_date FROM user_games WHERE user_id = $1 AND app_id = $2',
                    [userId, appId]
                );
                if (progress?.first_achievement_date && progress?.last_achievement_date) {
                    const hours = (new Date(progress.last_achievement_date) - new Date(progress.first_achievement_date)) / (1000 * 60 * 60);
                    return hours;
                }
                return Infinity;
            }

            case 'days_played': {
                // Count unique days with achievements
                const result = await db.getOne(`
          SELECT COUNT(DISTINCT DATE(unlock_time)) as days
          FROM user_achievements
          WHERE user_id = $1 AND app_id = $2 AND unlock_time IS NOT NULL
        `, [userId, appId]);
                return result?.days || 0;
            }

            case 'streak_days': {
                // Current streak of consecutive days with achievements
                return await this.calculateStreak(userId);
            }

            case 'genres_completed': {
                // Count unique genres of completed games
                // This would require genre data from Steam Store API
                const result = await db.getOne(`
          SELECT COUNT(DISTINCT app_id) as count
          FROM user_games
          WHERE user_id = $1 AND completion_percentage = 100
        `, [userId]);
                return Math.floor((result?.count || 0) / 3); // Rough estimate: assume 3 games = 1 genre
            }

            case 'months_dormant': {
                // Months since last achievement before completion
                const progress = await db.getOne(`
          SELECT synced_at, 
            (SELECT MAX(unlock_time) FROM user_achievements 
             WHERE user_id = $1 AND app_id = $2 AND unlock_time < synced_at - INTERVAL '1 day') as prev_unlock
          FROM user_games WHERE user_id = $1 AND app_id = $2
        `, [userId, appId]);

                if (progress?.prev_unlock) {
                    const months = (new Date() - new Date(progress.prev_unlock)) / (1000 * 60 * 60 * 24 * 30);
                    return months;
                }
                return 0;
            }

            default:
                return 0;
        }
    }

    // Calculate achievement streak
    async calculateStreak(userId) {
        const result = await db.getMany(`
      SELECT DISTINCT DATE(unlock_time) as day
      FROM user_achievements
      WHERE user_id = $1 AND unlock_time IS NOT NULL
      ORDER BY day DESC
      LIMIT 30
    `, [userId]);

        if (result.length === 0) return 0;

        let streak = 1;
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const firstDay = new Date(result[0].day);
        firstDay.setHours(0, 0, 0, 0);

        // Check if streak is current (includes today or yesterday)
        const diffFromToday = (today - firstDay) / (1000 * 60 * 60 * 24);
        if (diffFromToday > 1) return 0; // Streak is broken

        for (let i = 0; i < result.length - 1; i++) {
            const current = new Date(result[i].day);
            const next = new Date(result[i + 1].day);
            const diff = (current - next) / (1000 * 60 * 60 * 24);

            if (diff === 1) {
                streak++;
            } else {
                break;
            }
        }

        return streak;
    }

    // Add points to current season
    async addSeasonPoints(userId, points) {
        const season = await db.getOne('SELECT id FROM seasons WHERE is_active = true LIMIT 1');

        if (season) {
            await db.query(`
        INSERT INTO season_points (user_id, season_id, points)
        VALUES ($1, $2, $3)
        ON CONFLICT (user_id, season_id) DO UPDATE SET
          points = season_points.points + EXCLUDED.points,
          updated_at = CURRENT_TIMESTAMP
      `, [userId, season.id, points]);

            // Update house standings
            const user = await db.getOne('SELECT house_id FROM users WHERE id = $1', [userId]);
            if (user?.house_id) {
                await db.query(`
          INSERT INTO house_season_standings (house_id, season_id, total_points)
          VALUES ($1, $2, $3)
          ON CONFLICT (house_id, season_id) DO UPDATE SET
            total_points = house_season_standings.total_points + EXCLUDED.total_points,
            updated_at = CURRENT_TIMESTAMP
        `, [user.house_id, season.id, points]);
            }
        }
    }

    // Get user's medal summary
    async getUserMedals(userId) {
        const medals = await db.getMany(`
      SELECT um.*, md.medal_key, md.name, md.description, md.icon, md.tier,
             md.points as medal_points, md.house_bonus
      FROM user_medals um
      JOIN medal_definitions md ON um.medal_id = md.id
      WHERE um.user_id = $1
      ORDER BY um.earned_at DESC
    `, [userId]);

        const stats = await db.getOne(`
      SELECT 
        COUNT(*) as total_medals,
        SUM(points_earned) as total_points,
        COUNT(DISTINCT app_id) as games_with_medals
      FROM user_medals
      WHERE user_id = $1
    `, [userId]);

        return {
            medals,
            stats: {
                totalMedals: parseInt(stats?.total_medals || 0),
                totalPoints: parseInt(stats?.total_points || 0),
                gamesWithMedals: parseInt(stats?.games_with_medals || 0)
            }
        };
    }
}

module.exports = new MedalEngine();
