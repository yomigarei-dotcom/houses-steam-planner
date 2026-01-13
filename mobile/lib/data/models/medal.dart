import 'package:equatable/equatable.dart';

class Medal extends Equatable {
  final int id;
  final String medalKey;
  final String name;
  final String description;
  final String? icon;
  final String tier;
  final int points;
  final String? houseBonus;
  final int? appId;
  final String? gameName;
  final DateTime? earnedAt;
  final bool isNew;

  const Medal({
    required this.id,
    required this.medalKey,
    required this.name,
    required this.description,
    this.icon,
    this.tier = 'base',
    this.points = 100,
    this.houseBonus,
    this.appId,
    this.gameName,
    this.earnedAt,
    this.isNew = false,
  });

  factory Medal.fromJson(Map<String, dynamic> json) {
    return Medal(
      id: json['id'] ?? json['medalId'] ?? 0,
      medalKey: json['medal_key'] ?? json['medalKey'] ?? '',
      name: json['name'],
      description: json['description'] ?? '',
      icon: json['icon'],
      tier: json['tier'] ?? 'base',
      points: json['points'] ?? json['medal_points'] ?? 100,
      houseBonus: json['house_bonus'] ?? json['houseBonus'],
      appId: json['app_id'] ?? json['appId'],
      gameName: json['game_name'] ?? json['gameName'],
      earnedAt: json['earned_at'] != null 
          ? DateTime.parse(json['earned_at']) 
          : json['earnedAt'] != null 
              ? DateTime.parse(json['earnedAt'])
              : null,
      isNew: json['isNew'] ?? false,
    );
  }

  String get tierEmoji {
    switch (tier.toLowerCase()) {
      case 'gold': return '🥇';
      case 'silver': return '🥈';
      case 'bronze': return '🥉';
      default: return '🏅';
    }
  }

  @override
  List<Object?> get props => [id, medalKey, name, tier, points];
}

class MedalStats extends Equatable {
  final int totalMedals;
  final int totalPoints;
  final int gamesWithMedals;

  const MedalStats({
    this.totalMedals = 0,
    this.totalPoints = 0,
    this.gamesWithMedals = 0,
  });

  factory MedalStats.fromJson(Map<String, dynamic> json) {
    return MedalStats(
      totalMedals: json['totalMedals'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      gamesWithMedals: json['gamesWithMedals'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [totalMedals, totalPoints, gamesWithMedals];
}

class MedalData extends Equatable {
  final List<Medal> medals;
  final MedalStats stats;

  const MedalData({
    required this.medals,
    required this.stats,
  });

  factory MedalData.fromJson(Map<String, dynamic> json) {
    return MedalData(
      medals: (json['medals'] as List).map((m) => Medal.fromJson(m)).toList(),
      stats: MedalStats.fromJson(json['stats'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [medals, stats];
}
