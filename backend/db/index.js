const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Use SQLite for free tier deployment
const dbPath = process.env.DATABASE_PATH || path.join(__dirname, 'steamplanner.db');
let db = null;

// Initialize database
async function initialize() {
  return new Promise((resolve, reject) => {
    db = new sqlite3.Database(dbPath, (err) => {
      if (err) {
        console.error('Error opening database:', err);
        return reject(err);
      }
      console.log('Connected to SQLite database');

      // Run migrations
      db.serialize(() => {
        // Users table
        db.run(`
          CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            steam_id TEXT UNIQUE NOT NULL,
            username TEXT,
            avatar_url TEXT,
            profile_url TEXT,
            house_id INTEGER,
            start_date TEXT DEFAULT CURRENT_TIMESTAMP,
            general_points INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        `);

        // Houses table (The 4 Classes)
        db.run(`
          CREATE TABLE IF NOT EXISTS houses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            archetype TEXT NOT NULL,
            description TEXT,
            color_primary TEXT,
            color_secondary TEXT,
            icon TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        `);

        // Insert default houses
        db.run(`INSERT OR IGNORE INTO houses (id, name, archetype, description, color_primary, color_secondary, icon) VALUES 
          (1, 'Achiever', 'Record Class', 'Masters of completion and consistency', '#FFD700', '#1E3A5F', 'trophy'),
          (2, 'Explorer', 'Archive Class', 'Seekers of variety and discovery', '#20B2AA', '#1E3A5F', 'compass'),
          (3, 'Socializer', 'Club Class', 'Champions of community and cooperation', '#DC143C', '#FFFFFF', 'users'),
          (4, 'Killer', 'Duel Class', 'Hunters of rarity and competition', '#000000', '#39FF14', 'sword')
        `);

        // Seasons table
        db.run(`
          CREATE TABLE IF NOT EXISTS seasons (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT NOT NULL,
            is_active INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        `);

        // Create first season
        db.run(`INSERT OR IGNORE INTO seasons (id, name, start_date, end_date, is_active) VALUES
          (1, 'Season 1 - The Beginning', datetime('now'), datetime('now', '+3 months'), 1)
        `);

        // Games cache table
        db.run(`
          CREATE TABLE IF NOT EXISTS games (
            app_id INTEGER PRIMARY KEY,
            name TEXT,
            img_icon_url TEXT,
            img_logo_url TEXT,
            total_achievements INTEGER DEFAULT 0,
            cached_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        `);

        // User game progress
        db.run(`
          CREATE TABLE IF NOT EXISTS user_games (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            app_id INTEGER,
            playtime_forever INTEGER DEFAULT 0,
            achievements_unlocked INTEGER DEFAULT 0,
            achievements_total INTEGER DEFAULT 0,
            completion_percentage REAL DEFAULT 0,
            first_achievement_date TEXT,
            last_achievement_date TEXT,
            completed_at TEXT,
            synced_at TEXT DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(user_id, app_id)
          )
        `);

        // User achievements
        db.run(`
          CREATE TABLE IF NOT EXISTS user_achievements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            app_id INTEGER,
            api_name TEXT,
            unlocked INTEGER DEFAULT 0,
            unlock_time TEXT,
            synced_at TEXT DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(user_id, app_id, api_name)
          )
        `);

        // Medal definitions
        db.run(`
          CREATE TABLE IF NOT EXISTS medal_definitions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            medal_key TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            description TEXT,
            icon TEXT,
            tier TEXT DEFAULT 'base',
            points INTEGER DEFAULT 100,
            house_bonus TEXT,
            conditions TEXT,
            is_seasonal INTEGER DEFAULT 0,
            season_id INTEGER,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        `);

        // Insert default medals
        db.run(`INSERT OR IGNORE INTO medal_definitions (id, medal_key, name, description, icon, tier, points, conditions) VALUES
          (1, 'graduation', 'Graduation', 'Complete 100% of achievements in a game', 'graduation_cap', 'base', 100, '{"type":"AND","rules":[{"field":"completion_percentage","operator":"==","value":100}]}'),
          (2, 'rare_hunter', 'Rare Hunter', 'Complete a game with average rarity below 10%', 'diamond', 'gold', 500, '{"type":"AND","rules":[{"field":"completion_percentage","operator":"==","value":100},{"field":"average_rarity","operator":"<","value":10}]}'),
          (3, 'speed_demon', 'Speed Demon', 'Complete 100% within 24 hours of first achievement', 'lightning', 'gold', 400, '{"type":"AND","rules":[{"field":"completion_percentage","operator":"==","value":100},{"field":"completion_hours","operator":"<=","value":24}]}'),
          (4, 'marathon', 'Marathon', 'Complete 100% over 30+ different days', 'calendar', 'silver', 300, '{"type":"AND","rules":[{"field":"completion_percentage","operator":"==","value":100},{"field":"days_played","operator":">=","value":30}]}'),
          (5, 'backlog_slayer', 'Backlog Slayer', 'Complete a game untouched for 6+ months', 'skull', 'silver', 200, '{"type":"AND","rules":[{"field":"completion_percentage","operator":"==","value":100},{"field":"months_dormant","operator":">=","value":6}]}')
        `);

        // User medals
        db.run(`
          CREATE TABLE IF NOT EXISTS user_medals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            medal_id INTEGER,
            app_id INTEGER,
            game_name TEXT,
            points_earned INTEGER,
            earned_at TEXT DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(user_id, medal_id, app_id)
          )
        `);

        // Season points
        db.run(`
          CREATE TABLE IF NOT EXISTS season_points (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            season_id INTEGER,
            points INTEGER DEFAULT 0,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(user_id, season_id)
          )
        `);

        // House season standings
        db.run(`
          CREATE TABLE IF NOT EXISTS house_season_standings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            house_id INTEGER,
            season_id INTEGER,
            total_points INTEGER DEFAULT 0,
            rank INTEGER,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(house_id, season_id)
          )
        `);

        // Quiz questions
        db.run(`
          CREATE TABLE IF NOT EXISTS quiz_questions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            question TEXT NOT NULL,
            options TEXT NOT NULL,
            order_index INTEGER DEFAULT 0
          )
        `);

        // Insert quiz questions
        db.run(`INSERT OR IGNORE INTO quiz_questions (id, question, options, order_index) VALUES
          (1, 'When starting a new game, what is your first instinct?', '[{"text":"Check achievement list and plan my route","house":"achiever"},{"text":"Explore every corner before progressing","house":"explorer"},{"text":"Find friends to play with","house":"socializer"},{"text":"Rush to beat my friends times","house":"killer"}]', 1),
          (2, 'A hidden achievement is revealed. You:', '[{"text":"Add it to my checklist immediately","house":"achiever"},{"text":"Love the mystery, will discover naturally","house":"explorer"},{"text":"Ask community for hints","house":"socializer"},{"text":"Race to get it before anyone else","house":"killer"}]', 2),
          (3, 'Your ideal gaming session is:', '[{"text":"Methodically crossing off achievements","house":"achiever"},{"text":"Trying a completely new genre","house":"explorer"},{"text":"Co-op night with friends","house":"socializer"},{"text":"Competitive ranked matches","house":"killer"}]', 3),
          (4, 'You see a game with 0.1% completion rate. You think:', '[{"text":"Challenge accepted, adding to backlog","house":"achiever"},{"text":"Interesting, what makes it so hard?","house":"explorer"},{"text":"Wonder if there is a group tackling it","house":"socializer"},{"text":"Perfect flex when I complete it","house":"killer"}]', 4),
          (5, 'Your Steam profile showcases:', '[{"text":"Perfect games counter","house":"achiever"},{"text":"Diverse game collection","house":"explorer"},{"text":"Friends list and groups","house":"socializer"},{"text":"Rare achievement showcase","house":"killer"}]', 5),
          (6, 'A game requires 200 hours for 100%. You:', '[{"text":"Plan it out, worth the completion","house":"achiever"},{"text":"Only if the journey is interesting","house":"explorer"},{"text":"Fun if playing with others","house":"socializer"},{"text":"Speed-run strategies exist?","house":"killer"}]', 6),
          (7, 'Your backlog has 100+ games. Priority goes to:', '[{"text":"Games closest to 100%","house":"achiever"},{"text":"Games I have not tried yet","house":"explorer"},{"text":"Games friends are playing","house":"socializer"},{"text":"Games with rare achievements","house":"killer"}]', 7),
          (8, 'Online achievements are:', '[{"text":"Annoying but necessary to complete","house":"achiever"},{"text":"Opportunity to meet new strategies","house":"explorer"},{"text":"Best part - playing with people!","house":"socializer"},{"text":"Where I prove my skill","house":"killer"}]', 8),
          (9, 'Your dream feature in an achievement tracker:', '[{"text":"Detailed completion statistics","house":"achiever"},{"text":"Discovery recommendations","house":"explorer"},{"text":"Friend activity feed","house":"socializer"},{"text":"Competitive leaderboards","house":"killer"}]', 9),
          (10, 'When you 100% a game, you feel:', '[{"text":"Satisfied - another one complete","house":"achiever"},{"text":"Ready for the next adventure","house":"explorer"},{"text":"Excited to share with friends","house":"socializer"},{"text":"Victorious - I conquered it","house":"killer"}]', 10)
        `);

        console.log('Database tables created successfully');
        resolve();
      });
    });
  });
}

// Query helper - promisified
// Helper to convert Postgres style params ($1, $2) to SQLite style (?)
function convertSql(sql) {
  let paramCount = 0;
  return sql.replace(/\$[0-9]+/g, () => '?');
}

// Query helper - promisified
function query(sql, params = []) {
  return new Promise((resolve, reject) => {
    // If it's a SELECT, use all
    if (sql.trim().toUpperCase().startsWith('SELECT')) {
      db.all(convertSql(sql), params, (err, rows) => {
        if (err) reject(err);
        else resolve({ rows });
      });
    } else {
      // Otherwise use run
      db.run(convertSql(sql), params, function (err) {
        if (err) reject(err);
        else resolve({ rows: [], rowCount: this.changes, lastID: this.lastID });
      });
    }
  });
}

// Get one row
async function getOne(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.get(convertSql(sql), params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
}

// Get many rows
async function getMany(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.all(convertSql(sql), params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows || []);
    });
  });
}

// Run insert/update
function run(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(convertSql(sql), params, function (err) {
      if (err) reject(err);
      else resolve({ rows: [], lastID: this.lastID, changes: this.changes });
    });
  });
}

module.exports = {
  initialize,
  query,
  getOne,
  getMany,
  run
};
