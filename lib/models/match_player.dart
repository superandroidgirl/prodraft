import 'match_enums.dart';

class MatchSkill {
  final String id;
  final String name;
  final String description;
  final PlayerRarity rarity;
  
  // Potential stats affected: 'shooting3', 'defense', etc.
  final Map<String, double> affectedStats;
  final String visualEffect;

  const MatchSkill({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.affectedStats,
    this.visualEffect = 'ripple',
  });
}

class MatchPlayer {
  final String id;
  final String name;
  final PlayerPosition position;
  final PlayerRarity rarity;
  
  // Core Stats (1-99)
  final int overall;
  final int offense;
  final int defense;
  final int shooting2;
  final int shooting3;
  final int passing;
  final int dribbling;
  final int rebounding;
  final int speed;
  final int strength;
  final int iq;
  
  // Dynamic Stats
  double stamina; // 0.0 to 100.0
  PlayerStatus status;
  
  final int jerseyNumber;
  final List<MatchSkill> skills;
  final List<String> teamStyleTags; // e.g. ['run_and_gun', 'spacing']

  MatchPlayer({
    required this.id,
    required this.name,
    required this.position,
    required this.rarity,
    required this.overall,
    required this.offense,
    required this.defense,
    required this.shooting2,
    required this.shooting3,
    required this.passing,
    required this.dribbling,
    required this.rebounding,
    required this.speed,
    required this.strength,
    required this.iq,
    this.jerseyNumber = 0,
    this.stamina = 100.0,
    this.status = PlayerStatus.normal,
    required this.skills,
    this.teamStyleTags = const [],
  });

  // Calculate tired penalty (e.g. if stamina < 40, stats drop)
  double get staminaFactor => stamina < 40 ? 0.85 : 1.0;
  
  double getEffectiveStat(String statName) {
    // Basic implementation: would sum base stat + skill bonuses
    int base = 0;
    switch(statName) {
      case 'offense': base = offense; break;
      case 'defense': base = defense; break;
      case 'shooting3': base = shooting3; break;
      case 'speed': base = speed; break;
      // ... same for others
    }
    return base * staminaFactor;
  }
}
