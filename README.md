# SteamPlanner

The ultimate Steam achievement tracker with House system, medals, and seasons.

## Project Structure

```
steam_planner/
├── backend/          # Node.js/Express API
│   ├── routes/       # API routes (auth, steam, medals, houses, seasons)
│   ├── services/     # Steam API wrapper, medal engine
│   └── db/           # PostgreSQL schema
│
└── mobile/           # Flutter app
    └── lib/
        ├── core/     # Theme, routing
        ├── data/     # Models, repositories, API
        └── features/ # Screens and BLoCs
```

## Quick Start

### 1. Backend Setup

```bash
cd backend
npm install
cp .env.example .env
# Fill in STEAM_API_KEY, DATABASE_URL, JWT_SECRET
npm run dev
```

### 2. Mobile Setup

```bash
cd mobile
flutter pub get
flutter run
```

## Deploy

### Backend (Render)

1. Create Web Service on Render
2. Connect GitHub repo
3. Set environment variables
4. Deploy!

### Mobile (APK)

```bash
flutter build apk --release
# APK at build/app/outputs/flutter-apk/app-release.apk
```

## Features

- ✅ Steam OpenID login
- ✅ 4 Houses (Achiever/Explorer/Socializer/Killer)
- ✅ Medal auto-evaluation
- ✅ House Cup with dual points
- ✅ Weekly planner
- ✅ Varsity + Neon UI
