import 'package:flutter/material.dart';

/// Color palettes for the 4 Houses
class HouseColors {
  // Achiever - Record Class (Gold + Navy)
  static const achiever = HouseColorPalette(
    id: 1,
    name: 'Achiever',
    archetype: 'Record Class',
    primary: Color(0xFFFFD700),    // Gold
    secondary: Color(0xFF1E3A5F),  // Navy
    accent: Color(0xFFFFA500),     // Orange gold
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    ),
  );

  // Explorer - Archive Class (Teal + Navy)
  static const explorer = HouseColorPalette(
    id: 2,
    name: 'Explorer',
    archetype: 'Archive Class',
    primary: Color(0xFF20B2AA),    // Teal
    secondary: Color(0xFF1E3A5F),  // Navy
    accent: Color(0xFF00CED1),     // Dark turquoise
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF20B2AA), Color(0xFF00CED1)],
    ),
  );

  // Socializer - Club Class (Red + White)
  static const socializer = HouseColorPalette(
    id: 3,
    name: 'Socializer',
    archetype: 'Club Class',
    primary: Color(0xFFDC143C),    // Crimson
    secondary: Color(0xFFFFFFFF),  // White
    accent: Color(0xFFFF4500),     // Orange red
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFDC143C), Color(0xFFFF4500)],
    ),
  );

  // Killer - Duel Class (Black + Neon Green)
  static const killer = HouseColorPalette(
    id: 4,
    name: 'Killer',
    archetype: 'Duel Class',
    primary: Color(0xFF000000),    // Black
    secondary: Color(0xFF39FF14),  // Neon green
    accent: Color(0xFF00FF00),     // Lime
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A1A1A), Color(0xFF39FF14)],
    ),
  );

  // Get house by ID
  static HouseColorPalette getById(int id) {
    switch (id) {
      case 1: return achiever;
      case 2: return explorer;
      case 3: return socializer;
      case 4: return killer;
      default: return achiever;
    }
  }

  // Get house by name
  static HouseColorPalette getByName(String name) {
    switch (name.toLowerCase()) {
      case 'achiever': return achiever;
      case 'explorer': return explorer;
      case 'socializer': return socializer;
      case 'killer': return killer;
      default: return achiever;
    }
  }

  static List<HouseColorPalette> get all => [achiever, explorer, socializer, killer];
}

class HouseColorPalette {
  final int id;
  final String name;
  final String archetype;
  final Color primary;
  final Color secondary;
  final Color accent;
  final LinearGradient gradient;

  const HouseColorPalette({
    required this.id,
    required this.name,
    required this.archetype,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.gradient,
  });

  // Icon for each house
  IconData get icon {
    switch (name.toLowerCase()) {
      case 'achiever': return Icons.emoji_events;
      case 'explorer': return Icons.explore;
      case 'socializer': return Icons.groups;
      case 'killer': return Icons.military_tech;
      default: return Icons.shield;
    }
  }

  // Glow effect for cards/widgets
  List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: primary.withOpacity(0.4),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];
}
