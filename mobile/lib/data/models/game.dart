import 'package:equatable/equatable.dart';

class Game extends Equatable {
  final int appId;
  final String name;
  final String? iconUrl;
  final String? headerUrl;
  final int playtimeForever;
  final int? playtimeRecent;
  final int achievementsUnlocked;
  final int achievementsTotal;
  final double completionPercentage;
  final bool isComplete;
  final DateTime? lastPlayed;

  const Game({
    required this.appId,
    required this.name,
    this.iconUrl,
    this.headerUrl,
    this.playtimeForever = 0,
    this.playtimeRecent,
    this.achievementsUnlocked = 0,
    this.achievementsTotal = 0,
    this.completionPercentage = 0,
    this.isComplete = false,
    this.lastPlayed,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      appId: json['appId'],
      name: json['name'],
      iconUrl: json['iconUrl'],
      headerUrl: json['headerUrl'],
      playtimeForever: json['playtimeForever'] ?? 0,
      playtimeRecent: json['playtimeRecent'],
      achievementsUnlocked: json['achievementsUnlocked'] ?? 0,
      achievementsTotal: json['achievementsTotal'] ?? 0,
      completionPercentage: (json['completionPercentage'] ?? 0).toDouble(),
      isComplete: json['isComplete'] ?? false,
      lastPlayed: json['lastPlayed'] != null ? DateTime.parse(json['lastPlayed']) : null,
    );
  }

  String get playtimeFormatted {
    final hours = playtimeForever ~/ 60;
    final minutes = playtimeForever % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get progressText => '$achievementsUnlocked / $achievementsTotal';

  bool get hasAchievements => achievementsTotal > 0;

  @override
  List<Object?> get props => [appId, name, completionPercentage, isComplete];
}

class Achievement extends Equatable {
  final String apiName;
  final String displayName;
  final String description;
  final String? icon;
  final String? iconGray;
  final bool hidden;
  final bool unlocked;
  final DateTime? unlockTime;
  final double globalPercent;

  const Achievement({
    required this.apiName,
    required this.displayName,
    required this.description,
    this.icon,
    this.iconGray,
    this.hidden = false,
    this.unlocked = false,
    this.unlockTime,
    this.globalPercent = 0,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      apiName: json['apiName'],
      displayName: json['displayName'],
      description: json['description'] ?? 'Hidden',
      icon: json['icon'],
      iconGray: json['iconGray'],
      hidden: json['hidden'] ?? false,
      unlocked: json['unlocked'] ?? false,
      unlockTime: json['unlockTime'] != null ? DateTime.parse(json['unlockTime']) : null,
      globalPercent: (json['globalPercent'] ?? 0).toDouble(),
    );
  }

  String get rarityLabel {
    if (globalPercent < 5) return 'Ultra Rare';
    if (globalPercent < 10) return 'Very Rare';
    if (globalPercent < 25) return 'Rare';
    if (globalPercent < 50) return 'Uncommon';
    return 'Common';
  }

  @override
  List<Object?> get props => [apiName, unlocked, globalPercent];
}

class GameAchievementData extends Equatable {
  final String gameName;
  final List<Achievement> achievements;
  final int total;
  final int unlocked;
  final int locked;
  final double completionPercentage;
  final double averageRarity;
  final bool isComplete;

  const GameAchievementData({
    required this.gameName,
    required this.achievements,
    required this.total,
    required this.unlocked,
    required this.locked,
    required this.completionPercentage,
    required this.averageRarity,
    required this.isComplete,
  });

  factory GameAchievementData.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] ?? {};
    return GameAchievementData(
      gameName: json['gameName'],
      achievements: (json['achievements'] as List)
          .map((a) => Achievement.fromJson(a))
          .toList(),
      total: stats['total'] ?? 0,
      unlocked: stats['unlocked'] ?? 0,
      locked: stats['locked'] ?? 0,
      completionPercentage: (stats['completionPercentage'] ?? 0).toDouble(),
      averageRarity: (stats['averageRarity'] ?? 0).toDouble(),
      isComplete: stats['isComplete'] ?? false,
    );
  }

  @override
  List<Object?> get props => [gameName, total, unlocked, isComplete];
}
