# SteamPlanner Backend

The ultimate Steam achievement tracker with House system, medals, and seasons.

## Quick Start

```bash
# Install dependencies
npm install

# Copy environment file and fill in values
cp .env.example .env

# Start development server
npm run dev
```

## Required Environment Variables

- `STEAM_API_KEY` - Get from https://steamcommunity.com/dev/apikey
- `DATABASE_URL` - PostgreSQL connection string
- `JWT_SECRET` - Random secret for JWT tokens

## API Endpoints

### Auth
- `GET /auth/steam` - Initiate Steam login
- `GET /auth/steam/callback` - Steam callback
- `GET /auth/me` - Get current user

### Steam Data
- `GET /api/steam/games` - Get user's library
- `GET /api/steam/games/:appId/achievements` - Get achievements
- `POST /api/steam/sync` - Full library sync

### Medals
- `GET /api/medals` - Get user's medals
- `POST /api/medals/evaluate/:appId` - Evaluate medals for game
- `GET /api/medals/definitions` - Get all medal definitions

### Houses
- `GET /api/houses` - Get all 4 houses
- `GET /api/houses/cup` - House Cup standings
- `GET /api/houses/quiz` - Get quiz questions
- `POST /api/houses/quiz/submit` - Submit quiz answers

### Seasons
- `GET /api/seasons/current` - Current season info
- `GET /api/seasons/leaderboard` - Season leaderboard

## Deploy to Render

1. Create a new Web Service
2. Connect your GitHub repo
3. Set environment variables
4. Deploy!
