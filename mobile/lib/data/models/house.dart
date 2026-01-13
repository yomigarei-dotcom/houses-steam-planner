import 'package:equatable/equatable.dart';

class House extends Equatable {
  final int id;
  final String name;
  final String archetype;
  final String? description;
  final String colorPrimary;
  final String colorSecondary;
  final String? icon;
  final int memberCount;
  final int totalPoints;
  final int? rank;

  const House({
    required this.id,
    required this.name,
    required this.archetype,
    this.description,
    required this.colorPrimary,
    required this.colorSecondary,
    this.icon,
    this.memberCount = 0,
    this.totalPoints = 0,
    this.rank,
  });

  factory House.fromJson(Map<String, dynamic> json) {
    return House(
      id: json['id'],
      name: json['name'],
      archetype: json['archetype'],
      description: json['description'],
      colorPrimary: json['color_primary'] ?? json['colorPrimary'] ?? '#FFD700',
      colorSecondary: json['color_secondary'] ?? json['colorSecondary'] ?? '#1E3A5F',
      icon: json['icon'],
      memberCount: json['member_count'] ?? json['memberCount'] ?? json['members'] ?? 0,
      totalPoints: json['total_points'] ?? json['totalPoints'] ?? json['points'] ?? 0,
      rank: json['rank'],
    );
  }

  @override
  List<Object?> get props => [id, name, totalPoints, rank];
}

class HouseCupData extends Equatable {
  final List<House> generalStandings;
  final List<House>? seasonStandings;
  final int? seasonId;
  final String? seasonName;

  const HouseCupData({
    required this.generalStandings,
    this.seasonStandings,
    this.seasonId,
    this.seasonName,
  });

  factory HouseCupData.fromJson(Map<String, dynamic> json) {
    return HouseCupData(
      generalStandings: (json['general']['standings'] as List)
          .map((h) => House.fromJson(h))
          .toList(),
      seasonStandings: json['season'] != null
          ? (json['season']['standings'] as List)
              .map((h) => House.fromJson(h))
              .toList()
          : null,
      seasonId: json['season']?['seasonId'],
      seasonName: json['season']?['seasonName'],
    );
  }

  @override
  List<Object?> get props => [generalStandings, seasonStandings];
}

class QuizQuestion extends Equatable {
  final int id;
  final String question;
  final List<QuizOption> options;
  final int orderIndex;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.orderIndex,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      question: json['question'],
      options: (json['options'] as List).map((o) => QuizOption.fromJson(o)).toList(),
      orderIndex: json['order_index'] ?? json['orderIndex'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, question, orderIndex];
}

class QuizOption extends Equatable {
  final String text;
  final String house;

  const QuizOption({
    required this.text,
    required this.house,
  });

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      text: json['text'],
      house: json['house'],
    );
  }

  @override
  List<Object?> get props => [text, house];
}
