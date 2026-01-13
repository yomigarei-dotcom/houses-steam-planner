import '../models/models.dart';
import '../remote/api_service.dart';
import '../local/database_helper.dart';

class AuthRepository {
  final ApiService _api;
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  User? _currentUser;

  AuthRepository(this._api);

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<String> getLoginUrl() async {
    return await _api.getLoginUrl();
  }

  Future<void> handleAuthCallback(String token) async {
    await _api.setToken(token);
    await fetchCurrentUser();
  }

  Future<User?> fetchCurrentUser() async {
    try {
      final data = await _api.getCurrentUser();
      _currentUser = User.fromJson(data);
      
      // Save to local DB
      await _db.saveUser({
        'id': _currentUser!.id,
        'steam_id': _currentUser!.steamId,
        'username': _currentUser!.username,
        'avatar_url': _currentUser!.avatarUrl,
        'house_id': _currentUser!.houseId,
        'house_name': _currentUser!.houseName,
        'general_points': _currentUser!.generalPoints,
        'token': _api.token,
      });
      
      return _currentUser;
    } catch (e) {
      return null;
    }
  }

  Future<User?> checkExistingSession() async {
    // First try local DB
    final localUser = await _db.getUser();
    if (localUser != null && localUser['token'] != null) {
      await _api.setToken(localUser['token']);
      
      // Try to validate with server
      final serverUser = await fetchCurrentUser();
      if (serverUser != null) {
        return serverUser;
      }
    }
    return null;
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (e) {
      // Ignore errors, still clear local data
    }
    await _db.clearAll();
    _currentUser = null;
  }
}
