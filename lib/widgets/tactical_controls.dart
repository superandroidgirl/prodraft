import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../providers/battle_provider.dart';

class TacticalControls extends ConsumerStatefulWidget {
  const TacticalControls({super.key});

  @override
  ConsumerState<TacticalControls> createState() => _TacticalControlsState();
}

class _TacticalControlsState extends ConsumerState<TacticalControls> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final battleState = ref.watch(battleProvider);
    final battleNotifier = ref.read(battleProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        border: const Border(
          top: BorderSide(color: Color(0xFF30363D), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stamina Bar
          Row(
            children: [
              const Icon(Icons.bolt, color: Colors.amberAccent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: battleState.stamina / 100,
                  backgroundColor: Colors.white24,
                  color: Colors.amberAccent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${battleState.stamina}',
                style: GoogleFonts.shareTechMono(color: Colors.amberAccent),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Start / Tactical Row
          if (!battleState.isBattleStarted)
            Stack(
              alignment: Alignment.topCenter,
              children: [
                ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [Colors.green, Colors.blue, Colors.pink],
                ),
                _buildStartButton(battleNotifier),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTacticButton('ENGAGE', Colors.greenAccent, () {
                  if (battleNotifier.consumeStamina(10)) {
                    battleNotifier.simulateLogEntry('SYSTEM', '正在執行全場壓迫...');
                  } else {
                    _showStaminaDialog(context);
                  }
                }),
                _buildTacticButton('ISO', Colors.amberAccent, () {
                  if (battleNotifier.consumeStamina(15)) {
                    battleNotifier.simulateLogEntry('PLAYER', '發動單打戰術！');
                    battleNotifier.simulateLogEntry('SYSTEM', 'LeBron 觸發坦克切入...');
                  } else {
                    _showStaminaDialog(context);
                  }
                }),
                _buildTacticButton('REBOUND', Colors.lightBlueAccent, () {
                   if (battleNotifier.consumeStamina(5)) {
                    battleNotifier.simulateLogEntry('PLAYER', '爭取籃板球資源！');
                  } else {
                    _showStaminaDialog(context);
                  }
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BattleNotifier notifier) {
    return ElevatedButton(
      onPressed: () {
        _confettiController.play();
        notifier.startBattle();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00FF88),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        'START BATTLE / 開啟傳奇',
        style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTacticButton(String label, Color color, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
              color: color.withValues(alpha: 0.1),
            ),
            child: Icon(Icons.flash_on, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.shareTechMono(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showStaminaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        title: Text(
          '體力不足',
          style: GoogleFonts.orbitron(color: Colors.redAccent),
        ),
        content: const Text(
          '檢測到能量過低，是否前往實驗室購買「體能藥水」？',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('暫時不要'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
            child: const Text('前往購買', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
