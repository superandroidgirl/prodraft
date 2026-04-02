import 'package:flutter_riverpod/flutter_riverpod.dart';

class BattleState {
  final int stamina;
  final List<String> logs;
  final bool isBattleStarted;
  final bool isIntro;

  BattleState({
    required this.stamina,
    required this.logs,
    required this.isBattleStarted,
    required this.isIntro,
  });

  BattleState copyWith({
    int? stamina,
    List<String>? logs,
    bool? isBattleStarted,
    bool? isIntro,
  }) {
    return BattleState(
      stamina: stamina ?? this.stamina,
      logs: logs ?? this.logs,
      isBattleStarted: isBattleStarted ?? this.isBattleStarted,
      isIntro: isIntro ?? this.isIntro,
    );
  }
}

class BattleNotifier extends Notifier<BattleState> {
  @override
  BattleState build() {
    return BattleState(stamina: 100, logs: [], isBattleStarted: false, isIntro: false);
  }

  void startBattle() {
    state = state.copyWith(isBattleStarted: true, isIntro: true);
    addLog('SYSTEM: 正在初始化 3D 競技場...');
    addLog('SYSTEM: 檢測到 S 級球員，加載特殊技能組...');

    // Switch off intro after delay
    Future.delayed(const Duration(milliseconds: 3500), () {
      state = state.copyWith(isIntro: false);
    });
  }

  void addLog(String log) {
    state = state.copyWith(logs: [log, ...state.logs].take(50).toList());
  }

  bool consumeStamina(int amount) {
    if (state.stamina >= amount) {
      state = state.copyWith(stamina: state.stamina - amount);
      return true;
    }
    return false;
  }

  void simulateLogEntry(String player, String action) {
    addLog('[LOG] $player $action');
  }
}

final battleProvider = NotifierProvider<BattleNotifier, BattleState>(() {
  return BattleNotifier();
});
