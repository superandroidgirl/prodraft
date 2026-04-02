import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/glb_model.dart';
import 'battle_simulation_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  BattleSimulationScreen
//
//  • Forces LANDSCAPE orientation on entry, restores PORTRAIT on exit.
//  • Shows Basketball5v5BattleView (2.5D ISO court + cube players).
//  • The speed bar inside the view emits Navigator.pop('__skip__') which
//    this screen catches to show the random result modal directly.
// ─────────────────────────────────────────────────────────────────────────────

class BattleSimulationScreen extends ConsumerStatefulWidget {
  const BattleSimulationScreen({super.key});

  @override
  ConsumerState<BattleSimulationScreen> createState() =>
      _BattleSimulationScreenState();
}

class _BattleSimulationScreenState
    extends ConsumerState<BattleSimulationScreen> {

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _skipToResult() {
    final rng = math.Random();
    final allyScore = 80 + rng.nextInt(41);
    final enemyScore = 80 + rng.nextInt(41);
    final isWin = allyScore > enemyScore;
    final mvp = defaultAllyModels[rng.nextInt(defaultAllyModels.length)];
    final allyPts = List.generate(5, (_) => rng.nextInt(30));
    final enemyPts = List.generate(5, (_) => rng.nextInt(30));

    _showResultModal(
      isWin: isWin,
      allyScore: allyScore,
      enemyScore: enemyScore,
      mvpName: mvp.name,
      allyPts: allyPts,
      enemyPts: enemyPts,
    );
  }

  void _showResultModal({
    required bool isWin,
    required int allyScore,
    required int enemyScore,
    required String mvpName,
    required List<int> allyPts,
    required List<int> enemyPts,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BattleResultDialog(
        isWin: isWin,
        allyScore: allyScore,
        enemyScore: enemyScore,
        mvpName: mvpName,
        allyModels: defaultAllyModels,
        enemyModels: defaultEnemyModels,
        allyPts: allyPts,
        enemyPts: enemyPts,
        onClose: () => Navigator.of(context)
          ..pop()
          ..pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D18),
      body: SafeArea(
        child: Stack(
          children: [
            // ── 2.5D ISO battle view ──────────────────────────────────────
            Positioned.fill(
              child: Basketball5v5BattleView(
                allyModels: defaultAllyModels,
                enemyModels: defaultEnemyModels,
                onSkip: _skipToResult,
              ),
            ),
            // ── Minimal top HUD ───────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: _TopHud(onBack: () => Navigator.pop(context)),
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
//  _TopHud — Minimal landscape header
// ─────────────────────────────────────────────────────────────────────────────
class _TopHud extends StatelessWidget {
  final VoidCallback onBack;
  const _TopHud({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF060D18).withValues(alpha: 0.95),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15), width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),

          // Title
          Text(
            'THE ARENA',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF00FF88),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          Text(
            'LIVE SIMULATION',
            style: GoogleFonts.shareTechMono(
              color: Colors.white24,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _SkipButton
// ─────────────────────────────────────────────────────────────────────────────
class _SkipButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SkipButton({required this.onTap});

  @override
  State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) => GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xFF0D1117).withValues(alpha: 0.9),
            border: Border.all(
              color: Colors.amberAccent
                  .withValues(alpha: 0.4 + 0.5 * _glow.value),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amberAccent
                    .withValues(alpha: 0.15 + 0.2 * _glow.value),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fast_forward_rounded,
                  color: Colors.amberAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                '跳過動畫 / SKIP',
                style: GoogleFonts.orbitron(
                  color: Colors.amberAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _BattleResultDialog — Full-screen landscape result modal
// ─────────────────────────────────────────────────────────────────────────────
class _BattleResultDialog extends StatefulWidget {
  final bool isWin;
  final int allyScore;
  final int enemyScore;
  final String mvpName;
  final List<GlbModel> allyModels;
  final List<GlbModel> enemyModels;
  final List<int> allyPts;
  final List<int> enemyPts;
  final VoidCallback onClose;

  const _BattleResultDialog({
    required this.isWin,
    required this.allyScore,
    required this.enemyScore,
    required this.mvpName,
    required this.allyModels,
    required this.enemyModels,
    required this.allyPts,
    required this.enemyPts,
    required this.onClose,
  });

  @override
  State<_BattleResultDialog> createState() => _BattleResultDialogState();
}

class _BattleResultDialogState extends State<_BattleResultDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _scale =
        CurvedAnimation(parent: _ac, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeIn);
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  Color get _accentColor =>
      widget.isWin ? const Color(0xFF00FF88) : const Color(0xFFFF3B30);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: size.width * 0.92,
            height: size.height * 0.88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFF0A1628),
              border: Border.all(color: _accentColor.withValues(alpha: 0.6), width: 2),
              boxShadow: [
                BoxShadow(
                    color: _accentColor.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 4),
              ],
            ),
            child: Column(
              children: [
                // ── Header ─────────────────────────────────────────────────
                _buildResultHeader(),
                const Divider(color: Colors.white12, height: 1),

                // ── Score + MVP + Box Score ────────────────────────────────
                Expanded(
                  child: Row(
                    children: [
                      // Left: score + MVP
                      Expanded(flex: 2, child: _buildScorePanel()),
                      const VerticalDivider(
                          color: Colors.white12, width: 1),
                      // Right: box score
                      Expanded(flex: 3, child: _buildBoxScore()),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),

                // ── Close button ───────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.black,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        '確認 / CONFIRM',
                        style: GoogleFonts.orbitron(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.isWin ? '🏆  VICTORY' : '💀  DEFEAT',
            style: GoogleFonts.orbitron(
              color: _accentColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _accentColor.withValues(alpha: 0.4), width: 1),
            ),
            child: Text(
              'RANDOM SIM',
              style: GoogleFonts.shareTechMono(
                  color: _accentColor, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorePanel() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Score
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${widget.allyScore}',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF00FF88),
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(':',
                    style: GoogleFonts.orbitron(
                        color: Colors.white38, fontSize: 36)),
              ),
              Text(
                '${widget.enemyScore}',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFFFF3B30),
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'MY TEAM  vs  ENEMY',
            style: GoogleFonts.shareTechMono(
                color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 24),

          // MVP
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.amberAccent.withValues(alpha: 0.3), width: 1),
            ),
            child: Column(
              children: [
                Text('★  MVP',
                    style: GoogleFonts.orbitron(
                        color: Colors.amberAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  widget.mvpName,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxScore() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('BOX SCORE',
              style: GoogleFonts.orbitron(
                  color: Colors.white54, fontSize: 11, letterSpacing: 2)),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                // Ally column
                Expanded(
                  child: _scoreColumn(
                    label: '我方',
                    color: const Color(0xFF00FF88),
                    models: widget.allyModels,
                    pts: widget.allyPts,
                  ),
                ),
                const VerticalDivider(color: Colors.white12, width: 1),
                // Enemy column
                Expanded(
                  child: _scoreColumn(
                    label: '敵方',
                    color: const Color(0xFFFF3B30),
                    models: widget.enemyModels,
                    pts: widget.enemyPts,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreColumn({
    required String label,
    required Color color,
    required List<GlbModel> models,
    required List<int> pts,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(label,
              style: GoogleFonts.shareTechMono(
                  color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        ...List.generate(models.length, (i) {
          final player = models[i];
          final p = pts[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Row(
              children: [
                // Grade dot
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: player.grade == PlayerGrade.sClass
                        ? Colors.amberAccent
                        : color.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    player.name.split(' ').last,
                    style: GoogleFonts.shareTechMono(
                        color: Colors.white70, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$p PT',
                  style: GoogleFonts.orbitron(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
