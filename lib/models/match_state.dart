import 'package:flutter/material.dart';
import 'match_player.dart';
import 'match_enums.dart';

class MatchTeam {
  final String id;
  final String name;
  final List<MatchPlayer> starters; // Exactly 5
  final List<MatchPlayer> bench;

  MatchTeam({
    required this.id,
    required this.name,
    required this.starters,
    this.bench = const [],
  }) : assert(starters.length == 5);

  int get totalPower => starters.fold(0, (sum, p) => sum + p.overall);
}

class PossessionResult {
  final MatchOutcome outcome;
  final int points;
  final MatchPlayer? player;
  final String commentary;
  final AnimationType animType;
  final List<String> triggeredSkills;

  PossessionResult({
    required this.outcome,
    required this.points,
    this.player,
    required this.commentary,
    this.animType = AnimationType.idle,
    this.triggeredSkills = const [],
  });
}

class MatchState {
  bool isIntro = true;
  int allyScore = 0;
  int enemyScore = 0;
  int quarter = 1;
  int gameClock = 720; // 12 mins in seconds
  int shotClock = 24;
  
  bool isAllyPossession = true;
  final Map<String, Offset> playerPositions = {};
  /// The logical target positions for the current set.
  final Map<String, Offset> logicalPositions = {};
  /// The previous logical positions for smooth LERPing.
  final Map<String, Offset> prevLogicalPositions = {};
  /// Progress of the tactical transition (0.0 to 1.0).
  double moveProgress = 1.0;
  final Map<String, String> playerStates = {}; // 'idle', 'jog', 'slide', 'dribble'
  double animationPhase = 0.0;
  
  final List<PossessionResult> playByPlay = [];
  
  // Tactics
  OffensiveTactic currentOffense = OffensiveTactic.balanced;
  DefensiveTactic currentDefense = DefensiveTactic.manToMan;

  void addResult(PossessionResult res) {
    playByPlay.insert(0, res);
    if (isAllyPossession) {
      allyScore += res.points;
    } else {
      enemyScore += res.points;
    }
    // Swap possession if no offensive rebound
    if (res.outcome != MatchOutcome.offRebound) {
       isAllyPossession = !isAllyPossession;
       shotClock = 24;
    } else {
       shotClock = 14; // Reset to 14 on offensive rebound
    }
  }

  String get timeFormatted {
    int m = gameClock ~/ 60;
    int s = gameClock % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }
}
