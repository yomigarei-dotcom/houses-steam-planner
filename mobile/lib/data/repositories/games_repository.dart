import '../models/models.dart';
import '../remote/api_service.dart';
import '../local/database_helper.dart';

class GamesRepository {
  final ApiService _api;
  final DatabaseHelper _db = DatabaseHelper.instance;

  GamesRepository(this._api);

  Future<List<Game>> getGames({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      // Try local first
      final local = await _db.getGames();
      if (local.isNotEmpty) {
        return local.map((g) => Game(
          appId: g['app_id'],
          name: g['name'],
          iconUrl: g['icon_url'],
          headerUrl: g['header_url'],
          playtimeForever: g['playtime_forever'] ?? 0,
          achievementsUnlocked: g['achievements_unlocked'] ?? 0,
          achievementsTotal: g['achievements_total'] ?? 0,
          completionPercentage: (g['completion_percentage'] ?? 0).toDouble(),
          isComplete: g['is_complete'] == 1,
        )).toList();
      }
    }

    // Fetch from API
    final data = await _api.getGames();
    final games = (data['games'] as List).map((g) => Game.fromJson(g)).toList();
    
    // Save to local
    await _db.saveGames(data['games']);
    
    return games;
  }

  Future<GameAchievementData> getAchievements(int appId) async {
    final data = await _api.getAchievements(appId);
    final achievementData = GameAchievementData.fromJson(data);
    
    // Cache achievements locally
    await _db.saveAchievements(
      appId,
      data['achievements'].map<Map<String, dynamic>>((a) => a as Map<String, dynamic>).toList(),
    );
    
    return achievementData;
  }

  Future<Map<String, dynamic>> syncLibrary() async {
    final result = await _api.syncLibrary();
    
    // Refresh local games cache
    await getGames(forceRefresh: true);
    
    return result;
  }

  // Statistics
  Future<Map<String, dynamic>> getStats(List<Game> games) async {
    final totalGames = games.length;
    final gamesWithAchievements = games.where((g) => g.hasAchievements).length;
    final completedGames = games.where((g) => g.isComplete).length;
    final totalAchievements = games.fold<int>(0, (sum, g) => sum + g.achievementsTotal);
    final unlockedAchievements = games.fold<int>(0, (sum, g) => sum + g.achievementsUnlocked);
    final avgCompletion = gamesWithAchievements > 0
        ? games.where((g) => g.hasAchievements)
            .fold<double>(0, (sum, g) => sum + g.completionPercentage) / gamesWithAchievements
        : 0.0;
    final totalPlaytime = games.fold<int>(0, (sum, g) => sum + g.playtimeForever);

    return {
      'totalGames': totalGames,
      'gamesWithAchievements': gamesWithAchievements,
      'completedGames': completedGames,
      'completionRate': gamesWithAchievements > 0 ? (completedGames / gamesWithAchievements * 100) : 0,
      'totalAchievements': totalAchievements,
      'unlockedAchievements': unlockedAchievements,
      'achievementRate': totalAchievements > 0 ? (unlockedAchievements / totalAchievements * 100) : 0,
      'avgCompletion': avgCompletion,
      'totalPlaytimeHours': totalPlaytime ~/ 60,
    };
  }
}
