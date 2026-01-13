import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String steamId;
  final String username;
  final String? avatarUrl;
  final String? profileUrl;
  final int? houseId;
  final String? houseName;
  final String? houseArchetype;
  final String? houseColorPrimary;
  final String? houseColorSecondary;
  final int generalPoints;
  final DateTime? startDate;

  const User({
    required this.id,
    required this.steamId,
    required this.username,
    this.avatarUrl,
    this.profileUrl,
    this.houseId,
    this.houseName,
    this.houseArchetype,
    this.houseColorPrimary,
    this.houseColorSecondary,
    this.generalPoints = 0,
    this.startDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      steamId: json['steamId'],
      username: json['username'],
      avatarUrl: json['avatarUrl'],
      profileUrl: json['profileUrl'],
      houseId: json['houseId'],
      houseName: json['houseName'],
      houseArchetype: json['houseArchetype'],
      houseColorPrimary: json['houseColorPrimary'],
      houseColorSecondary: json['houseColorSecondary'],
      generalPoints: json['generalPoints'] ?? 0,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'steamId': steamId,
    'username': username,
    'avatarUrl': avatarUrl,
    'profileUrl': profileUrl,
    'houseId': houseId,
    'houseName': houseName,
    'houseArchetype': houseArchetype,
    'houseColorPrimary': houseColorPrimary,
    'houseColorSecondary': houseColorSecondary,
    'generalPoints': generalPoints,
    'startDate': startDate?.toIso8601String(),
  };

  bool get hasHouse => houseId != null;

  @override
  List<Object?> get props => [id, steamId, username, houseId, generalPoints];
}
