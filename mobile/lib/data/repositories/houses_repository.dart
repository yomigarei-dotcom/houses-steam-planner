import '../models/models.dart';
import '../remote/api_service.dart';

class HousesRepository {
  final ApiService _api;

  HousesRepository(this._api);

  Future<List<House>> getHouses() async {
    final data = await _api.getHouses();
    return data.map((h) => House.fromJson(h)).toList();
  }

  Future<HouseCupData> getHouseCup() async {
    final data = await _api.getHouseCup();
    return HouseCupData.fromJson(data);
  }

  Future<List<QuizQuestion>> getQuizQuestions() async {
    final data = await _api.getQuizQuestions();
    return data.map((q) => QuizQuestion.fromJson(q)).toList();
  }

  Future<House> submitQuiz(List<Map<String, String>> answers) async {
    final data = await _api.submitQuiz(answers.map((a) => {
      return {'questionId': a['questionId'], 'selectedHouse': a['house']};
    }).toList());
    
    return House.fromJson(data['house']);
  }

  Future<House> joinHouse(int houseId) async {
    final data = await _api.joinHouse(houseId);
    return House.fromJson(data['house']);
  }

  Future<List<Map<String, dynamic>>> getHouseMembers(int houseId) async {
    final data = await _api.getHouseMembers(houseId);
    return data.cast<Map<String, dynamic>>();
  }
}
