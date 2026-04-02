import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_state.dart';
import '../models/match_enums.dart';
import '../logic/match_engine.dart';
import '../data/mock_match_data.dart';

class StandardBattleNotifier extends Notifier<MatchState> {
  Timer? _timer;
  Timer? _visualTimer;
  bool isAuto = true;

  @override
  MatchState build() {
    final s = MatchState();
    _updateMatchupPositions(s);
    return s;
  }

  void resetMatch() {
    state = build();
  }

  void _updateMatchupPositions(MatchState s) {
    // Tactical coordinates for each position (PG, SG, SF, PF, C)
    final Map<PlayerPosition, Offset> allySpots = {
      PlayerPosition.pg: const Offset(0.5, 0.42),
      PlayerPosition.sg: const Offset(0.2, 0.38),
      PlayerPosition.sf: const Offset(0.8, 0.38),
      PlayerPosition.pf: const Offset(0.35, 0.18),
      PlayerPosition.c: const Offset(0.65, 0.18),
    };

    final Map<PlayerPosition, Offset> enemySpots = {
      PlayerPosition.pg: const Offset(0.5, 0.58),
      PlayerPosition.sg: const Offset(0.2, 0.62),
      PlayerPosition.sf: const Offset(0.8, 0.62),
      PlayerPosition.pf: const Offset(0.35, 0.82),
      PlayerPosition.c: const Offset(0.65, 0.82),
    };

    final ballCarrierId = s.playByPlay.isNotEmpty
        ? s.playByPlay.first.player?.id
        : null;

    for (int i = 0; i < 5; i++) {
       // Ally
       final ap = allyTeam.starters[i];
       final aId = ap.id;
       final aBase = allySpots[ap.position] ?? const Offset(0.5, 0.5);
       final aTarget = s.isAllyPossession ? aBase : aBase.translate(0, -0.05);
       s.prevLogicalPositions[aId] = aTarget;
       s.logicalPositions[aId] = aTarget;
       s.playerPositions[aId] = aTarget;
       s.playerStates[aId] = aId == ballCarrierId ? 'dribble' : (s.isAllyPossession ? 'off-ball' : 'defense');

       // Enemy
       final ep = enemyTeam.starters[i];
       final eId = ep.id;
       final eBase = enemySpots[ep.position] ?? const Offset(0.5, 0.5);
       final eTarget = s.isAllyPossession ? eBase.translate(0, 0.05) : eBase;
       s.prevLogicalPositions[eId] = eTarget;
       s.logicalPositions[eId] = eTarget;
       s.playerPositions[eId] = eTarget;
       s.playerStates[eId] = eId == ballCarrierId ? 'dribble' : (s.isAllyPossession ? 'defense' : 'off-ball');
    }
  }

  void startMatch() {
    _timer?.cancel();
    _visualTimer?.cancel();

    // Logic Timer (Starts immediately)
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (state.gameClock <= 0) {
        stopMatch();
        return;
      }
      nextPossession();
    });

    // 3. Visual Timer (Animations & Continuous Movement) - Starts immediately
    _visualTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _nextVisualTick();
    });
  }

  void stopMatch() {
    _timer?.cancel();
    _visualTimer?.cancel();
  }

  void _nextVisualTick() {
    final s = _copyState(state);
    s.animationPhase = (s.animationPhase + 0.1) % (math.pi * 2);

    // 1. Advance Tactical Transition (2.0s duration)
    s.moveProgress = math.min(1.0, s.moveProgress + 0.05);

    // 2. Apply Double-Layer Movement (Tactical LERP + Visual Jitter)
    for (var id in s.logicalPositions.keys) {
      final target = s.logicalPositions[id]!;
      final prev = s.prevLogicalPositions[id] ?? target;
      
      // Layer 1: Smooth tactical interpolation
      final base = Offset.lerp(prev, target, s.moveProgress) ?? target;

      final phase = s.animationPhase + id.hashCode % 10;
      final status = s.playerStates[id] ?? 'idle';

      // Layer 2: Autonomous movement / Jitter
      double dx = 0;
      double dy = 0;
      if (status == 'defense') {
        dx = math.sin(phase * 2.0) * 0.025;
        dy = math.cos(phase * 1.2) * 0.008;
      } else if (status == 'off-ball') {
        dx = math.cos(phase * 1.5) * 0.030;
        dy = math.sin(phase * 1.1) * 0.020;
      } else if (status == 'dribble') {
        dx = math.sin(phase * 2.5) * 0.010;
        dy = math.cos(phase * 3.5) * 0.018;
      } else {
        dx = math.sin(phase * 0.8) * 0.005;
        dy = math.cos(phase * 0.8) * 0.005;
      }

      s.playerPositions[id] = base.translate(dx, dy);
    }

    state = s;
  }

  void nextPossession() {
    if (state.gameClock <= 0) {
      stopMatch();
      return;
    }

    final newState = _copyState(state);
    
    // SMOOTH TRANSITION: Store current logical as previous before updating
    newState.prevLogicalPositions.clear();
    newState.prevLogicalPositions.addAll(newState.logicalPositions);
    newState.moveProgress = 0.0; // Restart LERP timer

    newState.gameClock -= 24;
    newState.shotClock = 24;

    final offense = newState.isAllyPossession ? allyTeam : enemyTeam;
    final defense = newState.isAllyPossession ? enemyTeam : allyTeam;

    final result = MatchEngine.simulatePossession(
      offense,
      defense,
      newState.currentOffense,
      newState.currentDefense,
      newState,
    );

    newState.addResult(result);
    _updateMatchupPositions(newState);
    state = newState;
  }

  void setOffenseTactic(OffensiveTactic t) {
    state = _copyState(state)..currentOffense = t;
  }

  void setDefenseTactic(DefensiveTactic t) {
    state = _copyState(state)..currentDefense = t;
  }

  MatchState _copyState(MatchState s) {
    final ns = MatchState()
      ..isIntro = s.isIntro
      ..allyScore = s.allyScore
      ..enemyScore = s.enemyScore
      ..quarter = s.quarter
      ..gameClock = s.gameClock
      ..shotClock = s.shotClock
      ..isAllyPossession = s.isAllyPossession
      ..playByPlay.addAll(s.playByPlay)
      ..currentOffense = s.currentOffense
      ..currentDefense = s.currentDefense
      ..animationPhase = s.animationPhase
      ..moveProgress = s.moveProgress;
    ns.playerPositions.addAll(s.playerPositions);
    ns.logicalPositions.addAll(s.logicalPositions);
    ns.prevLogicalPositions.addAll(s.prevLogicalPositions);
    ns.playerStates.addAll(s.playerStates);
    return ns;
  }
}

final standardBattleProvider =
    NotifierProvider<StandardBattleNotifier, MatchState>(() {
      return StandardBattleNotifier();
    });
