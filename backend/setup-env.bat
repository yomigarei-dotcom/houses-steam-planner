@echo off
echo Creating .env file for SteamPlanner backend...

(
echo # SteamPlanner Backend Environment Variables
echo.
echo # Steam API
echo STEAM_API_KEY=87EDAD5357EC5D23773A0F7B3504EBB9
echo.
echo # Server
echo PORT=3000
echo NODE_ENV=development
echo.
echo # Database ^(Render PostgreSQL - update after creating DB on Render^)
echo DATABASE_URL=postgresql://user:password@host:5432/steamplanner
echo.
echo # JWT Secret
echo JWT_SECRET=steamplanner_secret_key_2026_houses_cup_change_in_production
echo.
echo # Steam OpenID
echo STEAM_REALM=http://localhost:3000
echo STEAM_RETURN_URL=http://localhost:3000/auth/steam/callback
echo.
echo # Frontend URL
echo FRONTEND_URL=http://localhost:3000
echo MOBILE_SCHEME=steamplanner://
) > .env

echo .env file created successfully!
echo.
echo IMPORTANT: Update DATABASE_URL after creating PostgreSQL on Render
echo.
pause
