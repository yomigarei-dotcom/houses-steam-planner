import '../models/models.dart';
import '../remote/api_service.dart';
import '../local/database_helper.dart';

class MedalsRepository {
  final ApiService _api;
  final DatabaseHelper _db = DatabaseHelper.instance;

  MedalsRepository(this._api);

  Future<MedalData> getMedals({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      // Try local first
      final local = await _db.getMedals();
      if (local.isNotEmpty) {
        return MedalData(
          medals: local.map((m) => Medal(
            id: m['id'],
            medalKey: m['medal_key'],
            name: m['name'],
            description: m['description'],
            icon: m['icon'],
            tier: m['tier'],
            points: m['points'],
            appId: m['app_id'],
            gameName: m['game_name'],
            earnedAt: m['earned_at'] != null ? DateTime.parse(m['earned_at']) : null,
          )).toList(),
          stats: MedalStats(
            totalMedals: local.length,
            totalPoints: local.fold(0, (sum, m) => sum + (m['points'] as int)),
            gamesWithMedals: local.map((m) => m['app_id']).toSet().length,
          ),
        );
      }
    }

    // Fetch from API
    final data = await _api.getMedals();
    final medalData = MedalData.fromJson(data);
    
    // Save to local
    await _db.saveMedals(medalData.medals.map((m) => {
      return {
        'id': m.id,
        'medal_key': m.medalKey,
        'name': m.name,
        'description': m.description,
        'icon': m.icon,
        'tier': m.tier,
        'points': m.points,
        'app_id': m.appId,
        'game_name': m.gameName,
        'earned_at': m.earnedAt?.toIso8601String(),
      };
    }).toList());
    
    return medalData;
  }

  Future<List<Medal>> evaluateMedals(int appId) async {
    final data = await _api.evaluateMedals(appId);
    final newMedals = (data['newMedals'] as List)
        .map((m) => Medal.fromJson(m))
        .toList();
    
    // Refresh medal cache
    await getMedals(forceRefresh: true);
    
    return newMedals;
  }

  Future<List<Medal>> evaluateAllMedals() async {
    final data = await _api.evaluateAllMedals();
    final newMedals = (data['medals'] as List)
        .map((m) => Medal.fromJson(m))
        .toList();
    
    // Refresh medal cache
    await getMedals(forceRefresh: true);
    
    return newMedals;
  }

  Future<List<Medal>> getMedalDefinitions() async {
    final data = await _api.getMedalDefinitions();
    return data.map((m) => Medal.fromJson(m)).toList();
  }
}
