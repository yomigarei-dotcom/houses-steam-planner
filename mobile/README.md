# SteamPlanner Mobile App

The ultimate Steam achievement tracker with House system, medals, and varsity+neon aesthetics.

## Features

- 🔐 **Steam Login** - Secure OpenID authentication
- 🏆 **House Cup** - 4 Classes competing (Achiever/Explorer/Socializer/Killer)
- 🏅 **Medal System** - Auto-awarded medals for 100% completions
- 📊 **Achievement Tracking** - Full library sync with rarity stats
- 📅 **Weekly Planner** - Schedule your gaming sessions
- ✨ **Premium UI** - Varsity + Neon aesthetic with animations

## Setup

### Prerequisites

- Flutter SDK 3.0+
- Backend running (see `/backend`)

### Configuration

1. Update the API URL in `lib/data/remote/api_service.dart`:
   ```dart
   static const String baseUrl = 'https://your-backend.onrender.com';
   ```

2. Create assets directories:
   ```
   mkdir -p assets/images assets/animations
   ```

### Run

```bash
# Get dependencies
flutter pub get

# Run on device/emulator
flutter run

# Build APK
flutter build apk --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── core/
│   ├── theme/               # App theming (varsity + neon)
│   └── router/              # GoRouter navigation
├── data/
│   ├── models/              # User, Game, Medal, House
│   ├── local/               # SQLite database
│   ├── remote/              # API service
│   └── repositories/        # Data repositories
└── features/
    ├── auth/                # Login screen & BLoC
    ├── home/                # Main scaffold
    ├── house_cup/           # House Cup dashboard
    ├── vitrina/             # Medal showcase
    ├── games/               # Games list & detail
    ├── class_quiz/          # House assignment quiz
    └── planner/             # Weekly schedule
```

## The 4 Houses

| House | Archetype | Colors | Focus |
|-------|-----------|--------|-------|
| Achiever | Record Class | Gold + Navy | Completion, streaks |
| Explorer | Archive Class | Teal + Navy | Variety, discovery |
| Socializer | Club Class | Red + White | Community, co-op |
| Killer | Duel Class | Black + Neon | Competition, rarity |
