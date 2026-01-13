import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';  // Change to your Render URL
  
  late final Dio _dio;
  String? _token;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        print('API Error: ${error.message}');
        return handler.next(error);
      },
    ));

    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  bool get isAuthenticated => _token != null;
  String? get token => _token;

  // Auth endpoints
  Future<String> getLoginUrl() async {
    final response = await _dio.get('/auth/steam/mobile');
    return response.data['loginUrl'];
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get('/auth/me');
    return response.data;
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
    await clearToken();
  }

  // Steam endpoints
  Future<Map<String, dynamic>> getGames() async {
    final response = await _dio.get('/api/steam/games');
    return response.data;
  }

  Future<Map<String, dynamic>> getAchievements(int appId) async {
    final response = await _dio.get('/api/steam/games/$appId/achievements');
    return response.data;
  }

  Future<Map<String, dynamic>> syncLibrary() async {
    final response = await _dio.post('/api/steam/sync');
    return response.data;
  }

  // Medals endpoints
  Future<Map<String, dynamic>> getMedals() async {
    final response = await _dio.get('/api/medals');
    return response.data;
  }

  Future<Map<String, dynamic>> evaluateMedals(int appId) async {
    final response = await _dio.post('/api/medals/evaluate/$appId');
    return response.data;
  }

  Future<Map<String, dynamic>> evaluateAllMedals() async {
    final response = await _dio.post('/api/medals/evaluate-all');
    return response.data;
  }

  Future<List<dynamic>> getMedalDefinitions() async {
    final response = await _dio.get('/api/medals/definitions');
    return response.data['medals'];
  }

  // Houses endpoints
  Future<List<dynamic>> getHouses() async {
    final response = await _dio.get('/api/houses');
    return response.data['houses'];
  }

  Future<Map<String, dynamic>> getHouseCup() async {
    final response = await _dio.get('/api/houses/cup');
    return response.data;
  }

  Future<List<dynamic>> getQuizQuestions() async {
    final response = await _dio.get('/api/houses/quiz');
    return response.data['questions'];
  }

  Future<Map<String, dynamic>> submitQuiz(List<Map<String, dynamic>> answers) async {
    final response = await _dio.post('/api/houses/quiz/submit', data: {'answers': answers});
    return response.data;
  }

  Future<Map<String, dynamic>> joinHouse(int houseId) async {
    final response = await _dio.post('/api/houses/join/$houseId');
    return response.data;
  }

  Future<List<dynamic>> getHouseMembers(int houseId) async {
    final response = await _dio.get('/api/houses/$houseId/members');
    return response.data['members'];
  }

  // Seasons endpoints
  Future<Map<String, dynamic>> getCurrentSeason() async {
    final response = await _dio.get('/api/seasons/current');
    return response.data;
  }

  Future<Map<String, dynamic>> getSeasonLeaderboard({int? seasonId}) async {
    final response = await _dio.get('/api/seasons/leaderboard', 
        queryParameters: seasonId != null ? {'seasonId': seasonId} : null);
    return response.data;
  }

  Future<Map<String, dynamic>> getSeasonChallenges() async {
    final response = await _dio.get('/api/seasons/challenges');
    return response.data;
  }
}
