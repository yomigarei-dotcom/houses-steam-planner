const { Pool } = require('pg');

// Database pool
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// Initialize database tables
async function initialize() {
    const client = await pool.connect();
    try {
        await client.query(`
      -- Users table
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        steam_id VARCHAR(20) UNIQUE NOT NULL,
        username VARCHAR(100),
        avatar_url TEXT,
        profile_url TEXT,
        house_id INTEGER REFERENCES houses(id),
        start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        general_points INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      -- Houses table (The 4 Classes)
      CREATE TABLE IF NOT EXISTS houses (
        id SERIAL PRIMARY KEY,
        name VARCHAR(50) NOT NULL,
        archetype VARCHAR(50) NOT NULL,
        description TEXT,
        color_primary VARCHAR(7),
        color_secondary VARCHAR(7),
        icon VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      -- Insert default houses if not exist
      INSERT INTO houses (name, archetype, description, color_primary, color_secondary, icon)
      VALUES 
        ('Achiever', 'Record Class', 'Masters of completion and consistency', '#FFD700', '#1E3A5F', 'trophy'),
        ('Explorer', 'Archive Class', 'Seekers of variety and discovery', '#20B2AA', '#1E3A5F', 'compass'),
        ('Socializer', 'Club Class', 'Champions of community and cooperation', '#DC143C', '#FFFFFF', 'users'),
        ('Killer', 'Duel Class', 'Hunters of rarity and competition', '#000000', '#39FF14', 'sword')
      ON CONFLICT DO NOTHING;

      -- Seasons table
      CREATE TABLE IF NOT EXISTS seasons (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        start_date TIMESTAMP NOT NULL,
        end_date TIMESTAMP NOT NULL,
        is_active BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      -- Games cache table
      CREATE TABLE IF NOT EXISTS games (
        app_id INTEGER PRIMARY KEY,
        name VARCHAR(255),
        img_icon_url TEXT,
        img_logo_url TEXT,
        total_achievements INTEGER DEFAULT 0,
        cached_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      -- Achievement schemas cache
      CREATE TABLE IF NOT EXISTS achievement_schemas (
        id SERIAL PRIMARY KEY,
        app_id INTEGER REFERENCES games(app_id),
        api_name VARCHAR(255),
        display_name VARCHAR(255),
        description TEXT,
        icon_url TEXT,
        icon_gray_url TEXT,
        global_percent DECIMAL(5,2),
        cached_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(app_id, api_name)
      );

      -- User game progress
      CREATE TABLE IF NOT EXISTS user_games (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        app_id INTEGER REFERENCES games(app_id),
        playtime_forever INTEGER DEFAULT 0,
        achievements_unlocked INTEGER DEFAULT 0,
        achievements_total INTEGER DEFAULT 0,
        completion_percentage DECIMAL(5,2) DEFAULT 0,
        first_achievement_date TIMESTAMP,
        last_achievement_date TIMESTAMP,
        completed_at TIMESTAMP,
        synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, app_id)
      );

      -- User achievements
      CREATE TABLE IF NOT EXISTS user_achievements (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        app_id INTEGER,
        api_name VARCHAR(255),
        unlocked BOOLEAN DEFAULT false,
        unlock_time TIMESTAMP,
        synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, app_id, api_name)
      );

      -- Medal definitions
      CREATE TABLE IF NOT EXISTS medal_definitions (
        id SERIAL PRIMARY KEY,
        medal_key VARCHAR(50) UNIQUE NOT NULL,
        name VARCHAR(100) NOT NULL,
        description TEXT,
        icon VARCHAR(50),
        tier VARCHAR(20) DEFAULT 'base',
        points INTEGER DEFAULT 100,
        house_bonus VARCHAR(50),
        conditions JSONB,
        is_seasonal BOOLEAN DEFAULT false,
        season_id INTEGER REFERENCES seasons(id),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      -- User medals (earned)
      CREATE TABLE IF NOT EXISTS user_medals (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        medal_id INTEGER REFERENCES medal_definitions(id),
        app_id INTEGER,
        game_name VARCHAR(255),
        points_earned INTEGER,
        earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, medal_id, app_id)
      );

      -- Season points
      CREATE TABLE IF NOT EXISTS season_points (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        season_id INTEGER REFERENCES seasons(id),
        points INTEGER DEFAULT 0,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, season_id)
      );

      -- House season standings
      CREATE TABLE IF NOT EXISTS house_season_standings (
        id SERIAL PRIMARY KEY,
        house_id INTEGER REFERENCES houses(id),
        season_id INTEGER REFERENCES seasons(id),
        total_points INTEGER DEFAULT 0,
        rank INTEGER,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(house_id, season_id)
      );

      -- Class quiz questions
      CREATE TABLE IF NOT EXISTS quiz_questions (
        id SERIAL PRIMARY KEY,
        question TEXT NOT NULL,
        options JSONB NOT NULL,
        order_index INTEGER DEFAULT 0
      );

      -- Insert default medal definitions
      INSERT INTO medal_definitions (medal_key, name, description, icon, tier, points, conditions)
      VALUES 
        ('graduation', 'Graduation', 'Complete 100% of achievements in a game', 'graduation_cap', 'base', 100, 
          '{"type": "AND", "rules": [{"field": "completion_percentage", "operator": "==", "value": 100}]}'),
        ('rare_hunter', 'Rare Hunter', 'Complete a game with average rarity below 10%', 'diamond', 'gold', 500,
          '{"type": "AND", "rules": [{"field": "completion_percentage", "operator": "==", "value": 100}, {"field": "average_rarity", "operator": "<", "value": 10}]}'),
        ('speed_demon', 'Speed Demon', 'Complete 100% within 24 hours of first achievement', 'lightning', 'gold', 400,
          '{"type": "AND", "rules": [{"field": "completion_percentage", "operator": "==", "value": 100}, {"field": "completion_hours", "operator": "<=", "value": 24}]}'),
        ('marathon', 'Marathon', 'Complete 100% over 30+ different days', 'calendar', 'silver', 300,
          '{"type": "AND", "rules": [{"field": "completion_percentage", "operator": "==", "value": 100}, {"field": "days_played", "operator": ">=", "value": 30}]}'),
        ('consistency', 'Perfect Attendance', 'Earn achievements 7 days in a row', 'check_circle', 'base', 150,
          '{"type": "AND", "rules": [{"field": "streak_days", "operator": ">=", "value": 7}]}'),
        ('explorer', 'Genre Explorer', 'Complete games in 5 different genres', 'compass', 'silver', 250,
          '{"type": "AND", "rules": [{"field": "genres_completed", "operator": ">=", "value": 5}]}'),
        ('backlog_slayer', 'Backlog Slayer', 'Complete a game untouched for 6+ months', 'skull', 'silver', 200,
          '{"type": "AND", "rules": [{"field": "completion_percentage", "operator": "==", "value": 100}, {"field": "months_dormant", "operator": ">=", "value": 6}]}')
      ON CONFLICT (medal_key) DO NOTHING;

      -- Insert default quiz questions
      INSERT INTO quiz_questions (question, options, order_index)
      VALUES 
        ('When starting a new game, what''s your first instinct?', 
          '[{"text": "Check achievement list and plan my route", "house": "achiever"}, {"text": "Explore every corner before progressing", "house": "explorer"}, {"text": "Find friends to play with", "house": "socializer"}, {"text": "Rush to beat my friends'' times", "house": "killer"}]', 1),
        ('A hidden achievement is revealed. You:', 
          '[{"text": "Add it to my checklist immediately", "house": "achiever"}, {"text": "Love the mystery, will discover naturally", "house": "explorer"}, {"text": "Ask community for hints", "house": "socializer"}, {"text": "Race to get it before anyone else", "house": "killer"}]', 2),
        ('Your ideal gaming session is:', 
          '[{"text": "Methodically crossing off achievements", "house": "achiever"}, {"text": "Trying a completely new genre", "house": "explorer"}, {"text": "Co-op night with friends", "house": "socializer"}, {"text": "Competitive ranked matches", "house": "killer"}]', 3),
        ('You see a game with 0.1% completion rate. You think:', 
          '[{"text": "Challenge accepted, adding to backlog", "house": "achiever"}, {"text": "Interesting, what makes it so hard?", "house": "explorer"}, {"text": "Wonder if there''s a group tackling it", "house": "socializer"}, {"text": "Perfect flex when I complete it", "house": "killer"}]', 4),
        ('Your Steam profile showcases:', 
          '[{"text": "Perfect games counter", "house": "achiever"}, {"text": "Diverse game collection", "house": "explorer"}, {"text": "Friends list and groups", "house": "socializer"}, {"text": "Rare achievement showcase", "house": "killer"}]', 5),
        ('A game requires 200 hours for 100%. You:', 
          '[{"text": "Plan it out, worth the completion", "house": "achiever"}, {"text": "Only if the journey is interesting", "house": "explorer"}, {"text": "Fun if playing with others", "house": "socializer"}, {"text": "Speed-run strategies exist?", "house": "killer"}]', 6),
        ('Your backlog has 100+ games. Priority goes to:', 
          '[{"text": "Games closest to 100%", "house": "achiever"}, {"text": "Games I haven''t tried yet", "house": "explorer"}, {"text": "Games friends are playing", "house": "socializer"}, {"text": "Games with rare achievements", "house": "killer"}]', 7),
        ('Online achievements are:', 
          '[{"text": "Annoying but necessary to complete", "house": "achiever"}, {"text": "Opportunity to meet new strategies", "house": "explorer"}, {"text": "Best part - playing with people!", "house": "socializer"}, {"text": "Where I prove my skill", "house": "killer"}]', 8),
        ('Your dream feature in an achievement tracker:', 
          '[{"text": "Detailed completion statistics", "house": "achiever"}, {"text": "Discovery recommendations", "house": "explorer"}, {"text": "Friend activity feed", "house": "socializer"}, {"text": "Competitive leaderboards", "house": "killer"}]', 9),
        ('When you 100% a game, you feel:', 
          '[{"text": "Satisfied - another one complete", "house": "achiever"}, {"text": "Ready for the next adventure", "house": "explorer"}, {"text": "Excited to share with friends", "house": "socializer"}, {"text": "Victorious - I conquered it", "house": "killer"}]', 10)
      ON CONFLICT DO NOTHING;
    `);
        console.log('Database tables created successfully');
    } catch (error) {
        console.error('Error initializing database:', error);
        throw error;
    } finally {
        client.release();
    }
}

// Query helper
async function query(text, params) {
    const client = await pool.connect();
    try {
        const result = await client.query(text, params);
        return result;
    } finally {
        client.release();
    }
}

// Get single row
async function getOne(text, params) {
    const result = await query(text, params);
    return result.rows[0];
}

// Get multiple rows
async function getMany(text, params) {
    const result = await query(text, params);
    return result.rows;
}

module.exports = {
    pool,
    initialize,
    query,
    getOne,
    getMany
};
