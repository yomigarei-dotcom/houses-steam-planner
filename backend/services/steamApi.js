const axios = require('axios');
const NodeCache = require('node-cache');

// Cache for Steam API responses
const cache = new NodeCache({
    stdTTL: 3600, // 1 hour default
    checkperiod: 600
});

const STEAM_API_BASE = 'https://api.steampowered.com';
const STEAM_STORE_BASE = 'https://store.steampowered.com/api';

class SteamApiService {
    constructor() {
        this.apiKey = process.env.STEAM_API_KEY;
    }

    // Get user info via API
    async getPlayerSummary(steamId) {
        const cacheKey = `player_${steamId}`;
        const cached = cache.get(cacheKey);
        if (cached) return cached;

        try {
            const response = await axios.get(
                `${STEAM_API_BASE}/ISteamUser/GetPlayerSummaries/v2/`,
                { params: { key: this.apiKey, steamids: steamId } }
            );

            const player = response.data.response.players[0];
            cache.set(cacheKey, player, 1800); // 30 min cache
            return player;
        } catch (error) {
            console.error('Error fetching player summary:', error.message);
            throw error;
        }
    }

    // Get user's owned games
    async getOwnedGames(steamId, includePlayedFree = true) {
        const cacheKey = `games_${steamId}`;
        const cached = cache.get(cacheKey);
        if (cached) return cached;

        try {
            const response = await axios.get(
                `${STEAM_API_BASE}/IPlayerService/GetOwnedGames/v1/`,
                {
                    params: {
                        key: this.apiKey,
                        steamid: steamId,
                        include_appinfo: true,
                        include_played_free_games: includePlayedFree
                    }
                }
            );

            const games = response.data.response.games || [];
            cache.set(cacheKey, games, 900); // 15 min cache
            return games;
        } catch (error) {
            console.error('Error fetching owned games:', error.message);
            throw error;
        }
    }

    // Get player achievements for a specific game
    async getPlayerAchievements(steamId, appId) {
        const cacheKey = `achievements_${steamId}_${appId}`;
        const cached = cache.get(cacheKey);
        if (cached) return cached;

        try {
            const response = await axios.get(
                `${STEAM_API_BASE}/ISteamUserStats/GetPlayerAchievements/v1/`,
                {
                    params: {
                        key: this.apiKey,
                        steamid: steamId,
                        appid: appId,
                        l: 'english'
                    }
                }
            );

            const data = response.data.playerstats;
            cache.set(cacheKey, data, 300); // 5 min cache
            return data;
        } catch (error) {
            // Game might not have achievements
            if (error.response?.status === 400) {
                return { achievements: [] };
            }
            console.error(`Error fetching achievements for ${appId}:`, error.message);
            throw error;
        }
    }

    // Get game schema (achievement definitions)
    async getSchemaForGame(appId) {
        const cacheKey = `schema_${appId}`;
        const cached = cache.get(cacheKey);
        if (cached) return cached;

        try {
            const response = await axios.get(
                `${STEAM_API_BASE}/ISteamUserStats/GetSchemaForGame/v2/`,
                { params: { key: this.apiKey, appid: appId, l: 'english' } }
            );

            const schema = response.data.game;
            cache.set(cacheKey, schema, 86400); // 24 hour cache (rarely changes)
            return schema;
        } catch (error) {
            console.error(`Error fetching schema for ${appId}:`, error.message);
            throw error;
        }
    }

    // Get global achievement percentages
    async getGlobalAchievementPercentages(appId) {
        const cacheKey = `global_${appId}`;
        const cached = cache.get(cacheKey);
        if (cached) return cached;

        try {
            const response = await axios.get(
                `${STEAM_API_BASE}/ISteamUserStats/GetGlobalAchievementPercentagesForApp/v2/`,
                { params: { gameid: appId } }
            );

            const achievements = response.data.achievementpercentages?.achievements || [];
            cache.set(cacheKey, achievements, 3600); // 1 hour cache
            return achievements;
        } catch (error) {
            console.error(`Error fetching global stats for ${appId}:`, error.message);
            return [];
        }
    }

    // Get game details from Steam Store API
    async getGameDetails(appId) {
        const cacheKey = `store_${appId}`;
        const cached = cache.get(cacheKey);
        if (cached) return cached;

        try {
            const response = await axios.get(
                `${STEAM_STORE_BASE}/appdetails`,
                { params: { appids: appId } }
            );

            const data = response.data[appId]?.data;
            if (data) {
                cache.set(cacheKey, data, 86400); // 24 hour cache
            }
            return data;
        } catch (error) {
            console.error(`Error fetching store details for ${appId}:`, error.message);
            return null;
        }
    }

    // Combined: Get full achievement data with rarity
    async getFullAchievementData(steamId, appId) {
        try {
            const [playerAchievements, schema, globalStats] = await Promise.all([
                this.getPlayerAchievements(steamId, appId),
                this.getSchemaForGame(appId),
                this.getGlobalAchievementPercentages(appId)
            ]);

            const schemaAchievements = schema?.availableGameStats?.achievements || [];
            const globalMap = new Map(
                globalStats.map(a => [a.name.toLowerCase(), a.percent])
            );

            // Merge all data
            const achievements = schemaAchievements.map(schemaAch => {
                const playerAch = playerAchievements.achievements?.find(
                    pa => pa.apiname === schemaAch.name
                );
                const globalPercent = globalMap.get(schemaAch.name.toLowerCase()) || 0;

                return {
                    apiName: schemaAch.name,
                    displayName: schemaAch.displayName,
                    description: schemaAch.description || 'Hidden',
                    icon: schemaAch.icon,
                    iconGray: schemaAch.icongray,
                    hidden: schemaAch.hidden === 1,
                    unlocked: playerAch?.achieved === 1,
                    unlockTime: playerAch?.unlocktime ? new Date(playerAch.unlocktime * 1000) : null,
                    globalPercent: parseFloat(globalPercent.toFixed(2))
                };
            });

            // Calculate stats
            const totalCount = achievements.length;
            const unlockedCount = achievements.filter(a => a.unlocked).length;
            const completionPercentage = totalCount > 0
                ? parseFloat(((unlockedCount / totalCount) * 100).toFixed(2))
                : 0;
            const averageRarity = totalCount > 0
                ? parseFloat((achievements.reduce((sum, a) => sum + a.globalPercent, 0) / totalCount).toFixed(2))
                : 0;

            return {
                gameName: playerAchievements.gameName || schema?.gameName || `App ${appId}`,
                achievements,
                stats: {
                    total: totalCount,
                    unlocked: unlockedCount,
                    locked: totalCount - unlockedCount,
                    completionPercentage,
                    averageRarity,
                    isComplete: completionPercentage === 100
                }
            };
        } catch (error) {
            console.error(`Error getting full achievement data for ${appId}:`, error.message);
            throw error;
        }
    }

    // Clear cache for user (after sync)
    clearUserCache(steamId) {
        const keys = cache.keys().filter(k => k.includes(steamId));
        keys.forEach(k => cache.del(k));
    }
}

module.exports = new SteamApiService();
