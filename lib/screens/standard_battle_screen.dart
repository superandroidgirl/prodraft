import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/match_enums.dart';
import '../models/match_state.dart';
import '../models/match_player.dart';
import '../providers/standard_battle_provider.dart';
import '../data/mock_match_data.dart';

import 'package:flutter/services.dart';
import 'dart:ui';

class StandardBattleScreen extends ConsumerStatefulWidget {
  const StandardBattleScreen({super.key});

  @override
  ConsumerState<StandardBattleScreen> createState() => _StandardBattleScreenState();
}

class _StandardBattleScreenState extends ConsumerState<StandardBattleScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    Future.microtask(() {
      ref.read(standardBattleProvider.notifier).resetMatch();
      ref.read(standardBattleProvider.notifier).startMatch();
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(standardBattleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF060D18),
      body: Stack(
        children: [
          // 1. Central 2.5D Animation Area
          Positioned.fill(
            child: _MatchAnimationArea(state: state),
          ),

          // 2. Top Scoreboard
          Positioned(
            top: 12, left: 100, right: 100,
            child: _MatchTopBar(state: state),
          ),


          // 4. Bottom Tactical Controls
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _TacticalControlBar(
              onOffense: (t) => ref.read(standardBattleProvider.notifier).setOffenseTactic(t),
              onDefense: (t) => ref.read(standardBattleProvider.notifier).setDefenseTactic(t),
              currentOff: state.currentOffense,
              currentDef: state.currentDefense,
            ),
          ),

          // Close button
          Positioned(
            top: 12, left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

Offset logicalToIsometric(double x, double y, Size courtSize) {
  final ox = courtSize.width * 0.50;
  final oy = courtSize.height * 0.46;
  // Scale down to fit full court in landscape
  final fx = courtSize.width * 0.45;
  final fy = courtSize.height * 0.65;
  final ix = (x - 0.5) * fx - (y - 0.5) * fx;
  final iy = (x - 0.5) * fy * 0.5 + (y - 0.5) * fy * 0.5;
  return Offset(ox + ix, oy + iy);
}

double getScale(double y) => 0.55 + (y * 0.35);

class _MatchAnimationArea extends ConsumerStatefulWidget {
  final MatchState state;
  const _MatchAnimationArea({required this.state});

  @override
  ConsumerState<_MatchAnimationArea> createState() => _MatchAnimationAreaState();
}

class _MatchAnimationAreaState extends ConsumerState<_MatchAnimationArea> with SingleTickerProviderStateMixin {
  late AnimationController _swingController;
  @override
  void initState() {
    super.initState();
    _swingController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat();
  }

  @override
  void dispose() {
    _swingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // CRITICAL: Ensure we are using the LATEST state from the widget
    final currentPositions = widget.state.playerPositions;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF03080F),
        image: DecorationImage(image: NetworkImage('https://www.transparenttextures.com/patterns/carbon-fibre.png'), opacity: 0.1, repeat: ImageRepeat.repeat),
      ),
      child: Stack(
        children: [
          // 1. Background Court
          Positioned.fill(
            child: CustomPaint(
              painter: _HighFidelityIsoPainter(
                state: widget.state,
                positions: currentPositions,
                swingValue: _swingController.value,
                animationPhase: widget.state.animationPhase,
              ),
            ),
          ),
          
          // 3. Side Logs (Play-by-play)
          _SideLogs(state: widget.state),
        ],
      ),
    );
  }
}

class _SideLogs extends StatelessWidget {
  final MatchState state;
  const _SideLogs({required this.state});

  @override
  Widget build(BuildContext context) {
    final recent = state.playByPlay.take(5).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      child: Stack(
        children: [
        // Left Side Log
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black87, Colors.transparent], begin: Alignment.centerLeft, end: Alignment.centerRight)),
            child: ListView.separated(
              reverse: true,
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white10)),
                child: Text(recent[i].commentary, style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 11)),
              ),
            ),
          ),
        ),
        // Right Side Stats/Info
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.black87], begin: Alignment.centerLeft, end: Alignment.centerRight)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatTile(label: 'OFFENSE', value: state.currentOffense.name.toUpperCase()),
                const SizedBox(height: 8),
                _StatTile(label: 'DEFENSE', value: state.currentDefense.name.toUpperCase()),
                const SizedBox(height: 12),
                Text("POSS: ${state.isAllyPossession ? 'Lakers' : 'Nets'}", style: GoogleFonts.orbitron(color: Colors.amberAccent, fontSize: 10, letterSpacing: 2)),
              ],
            ),
          ),
        ),
      ],
    ),);
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: GoogleFonts.shareTechMono(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(value, style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}

class _HighFidelityIsoPainter extends CustomPainter {
  final MatchState state;
  final Map<String, Offset> positions;
  final double swingValue;
  final double animationPhase;
  _HighFidelityIsoPainter({required this.state, required this.positions, required this.swingValue, required this.animationPhase});

  @override
  void paint(Canvas canvas, Size size) {
    _drawCourt(canvas, size);
    _drawHoops(canvas, size);
    

    _drawPlayers(canvas, size);
  }

  void _drawCourt(Canvas canvas, Size size) {
    Offset i(double x, double y) => logicalToIsometric(x, y, size);
    final rect = Path()..addPolygon([i(0,0), i(1,0), i(1,1), i(0,1)], true);
    
    // Polished Wood Floor
    final gradient = LinearGradient(
      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(rect, Paint()..shader = gradient);
    
    final linePaint = Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawPath(rect, linePaint);
    canvas.drawLine(i(0, 0.5), i(1, 0.5), linePaint);
    canvas.drawCircle(i(0.5, 0.5), size.width * 0.08, linePaint);
    
    // Key areas with glow
    final keyPaint = Paint()..color = Colors.amberAccent.withValues(alpha: 0.1)..style = PaintingStyle.fill;
    void drawKeyArea(double yStart, double yEnd) {
      canvas.drawPath(Path()..addPolygon([i(0.35, yStart), i(0.65, yStart), i(0.65, yEnd), i(0.35, yEnd)], true), linePaint);
      canvas.drawPath(Path()..addPolygon([i(0.35, yStart), i(0.65, yStart), i(0.65, yEnd), i(0.35, yEnd)], true), keyPaint);
    }
    drawKeyArea(0, 0.18);
    drawKeyArea(1.0, 0.82);
  }

  void _drawHoops(Canvas canvas, Size size) {
    Offset i(double x, double y) => logicalToIsometric(x, y, size);
    void drawHoop(double x, double y) {
      final base = i(x, y);
      final scale = getScale(y);
      canvas.drawLine(base, base.translate(0, -50 * scale), Paint()..color = Colors.grey..strokeWidth = 4 * scale);
      canvas.drawRect(Rect.fromCenter(center: base.translate(0, -55 * scale), width: 32 * scale, height: 22 * scale), Paint()..color = Colors.white12);
      canvas.drawOval(Rect.fromCenter(center: base.translate(0, -48 * scale), width: 14 * scale, height: 8 * scale), Paint()..color = Colors.orange..style = PaintingStyle.stroke..strokeWidth = 2 * scale);
    }
    drawHoop(0.5, 0.05); // More inset for precision
    drawHoop(0.5, 0.95);
  }

  void _drawPlayers(Canvas canvas, Size size) {
    final sortedIds = positions.keys.toList()
      ..sort((a, b) => positions[a]!.dy.compareTo(positions[b]!.dy));

    for (final id in sortedIds) {
      final logPos = positions[id]!;
      // Apply jitter here (Persistent Base Movement Layer) in visual space to avoid logical drift
      final noiseX = math.sin(animationPhase * 2 + id.hashCode) * 0.002;
      final noiseY = math.cos(animationPhase * 1.5 + id.hashCode) * 0.002;
      final visualPos = logPos.translate(noiseX, noiseY);

      final pos = logicalToIsometric(visualPos.dx, visualPos.dy, size);
      final scale = getScale(visualPos.dy);
      
      final ally = allyTeam.starters.firstWhere((p) => p.id == id, orElse: () => MatchPlayer(id: '', name: '', position: PlayerPosition.c, rarity: PlayerRarity.r, overall: 0, offense: 0, defense: 0, shooting2: 0, shooting3: 0, passing: 0, dribbling: 0, rebounding: 0, speed: 0, strength: 0, iq: 0, skills: []));
      final enemy = enemyTeam.starters.firstWhere((p) => p.id == id, orElse: () => MatchPlayer(id: '', name: '', position: PlayerPosition.c, rarity: PlayerRarity.r, overall: 0, offense: 0, defense: 0, shooting2: 0, shooting3: 0, passing: 0, dribbling: 0, rebounding: 0, speed: 0, strength: 0, iq: 0, skills: []));
      
      final p = ally.id.isNotEmpty ? ally : enemy;
      final isAlly = ally.id.isNotEmpty;
      final color = isAlly ? const Color(0xFF00FF88) : const Color(0xFFFF3B30);
      final status = state.playerStates[id] ?? 'idle';
      
      _drawStateDrivenHuman(canvas, pos, scale, color, p.jerseyNumber, status);
    }
  }

  void _drawStateDrivenHuman(Canvas canvas, Offset base, double sc, Color jerseyColor, int jersey, String status) {
    // Colors
    final skinColor = const Color(0xFFFFDBAC);
    final hairColor = const Color(0xFF2D1B13);
    final isAlly = jerseyColor == const Color(0xFF00FF88);
    
    // POSTURE: Lower center of gravity for defense and dribbling
    final isLowStance = status == 'defense' || status == 'dribble';
    final crouchY = isLowStance ? 4.0 * sc : 0.0;

    // Persistent Base Movement Layer (bobbing and jitter)
    final idleBob = math.sin(animationPhase * 2) * 2 * sc;
    final root = base.translate(0, -idleBob + crouchY);
    
    final jerseyPaint = Paint()..color = jerseyColor;
    final skinPaint = Paint()..color = skinColor;
    final hairPaint = Paint()..color = hairColor;
    
    final textPainter = TextPainter(
      text: TextSpan(text: '$jersey', style: GoogleFonts.shareTechMono(color: Colors.black87, fontSize: 9 * sc, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();

    // Limb phases
    final phase = math.sin(animationPhase * 4);
    final swing = phase * (status == 'dribble' ? 0.6 : 0.3);

    // Shadow
    canvas.drawOval(Rect.fromCenter(center: base, width: 22 * sc, height: 9 * sc), Paint()..color = Colors.black26);

    // Legs: Upper (Thigh) & Lower (Calf)
    void drawLeg(double sideOffset, double s) {
      final hip = root.translate(sideOffset * sc, -20 * sc);
      // Joint angle: FIXED knee bend (minus direction for backward bend)
      final kneeAngle = - (0.3 + (s.abs() * 0.5) + (isLowStance ? 0.4 : 0.0));
      final upperL = 10.0 * sc;
      final lowerL = 10.0 * sc;
      
      final knee = hip.translate(math.sin(s) * upperL, math.cos(s) * upperL);
      final foot = knee.translate(math.sin(s + kneeAngle) * lowerL, math.cos(s + kneeAngle) * lowerL);
      
      canvas.drawLine(hip, knee, skinPaint..strokeWidth = 6 * sc..strokeCap = StrokeCap.round);
      canvas.drawLine(knee, foot, skinPaint..strokeWidth = 5 * sc..strokeCap = StrokeCap.round);
    }
    drawLeg(-5, swing);
    drawLeg(5, -swing);

    // Torso (Jersey Color)
    final torsoH = 26.0 * sc;
    final torsoTop = root.translate(0, -20 * sc - torsoH);
    final torsoBot = root.translate(0, -20 * sc);
    canvas.drawLine(torsoTop, torsoBot, jerseyPaint..strokeWidth = 16 * sc..strokeCap = StrokeCap.round);
    
    // Jersey Number
    textPainter.paint(canvas, root.translate(-textPainter.width/2, -38 * sc));

    // Arms: Upper & Forearm
    void drawArm(double sideOffset, double s, bool dribble) {
      final shoulder = root.translate(sideOffset * sc, -20 * sc - torsoH + 6 * sc);
      final armAngle = s + math.pi / 4;
      final elbowAngle = math.pi / 2.5;
      
      final elbow = shoulder.translate(math.sin(armAngle) * 9 * sc, math.cos(armAngle) * 9 * sc);
      final hand = elbow.translate(math.sin(armAngle + elbowAngle) * 8 * sc, math.cos(armAngle + elbowAngle) * 8 * sc);
      
      canvas.drawLine(shoulder, elbow, skinPaint..strokeWidth = 5 * sc..strokeCap = StrokeCap.round);
      canvas.drawLine(elbow, hand, skinPaint..strokeWidth = 4 * sc..strokeCap = StrokeCap.round);
      
      if (dribble) {
        final ballB = math.sin(animationPhase * 8).abs() * 15 * sc;
        canvas.drawCircle(hand.translate(0, 4 * sc + ballB), 5 * sc, Paint()..color = Colors.orangeAccent);
      }
    }
    drawArm(-9, -swing, status == 'dribble' && phase > 0);
    drawArm(9, swing, status == 'dribble' && phase <= 0);

    // Head (Skin Tone)
    final headR = 7.0 * sc;
    final headPos = root.translate(0, -20 * sc - torsoH - headR);
    canvas.drawCircle(headPos, headR, skinPaint);
    
    // Eyes: Looking towards the hoop
    final eyeYOffset = isAlly ? -2.5 * sc : 2.5 * sc;
    final eyeW = 1.0 * sc;
    canvas.drawCircle(headPos.translate(-2.2 * sc, eyeYOffset), eyeW, Paint()..color = Colors.black87);
    canvas.drawCircle(headPos.translate(2.2 * sc, eyeYOffset), eyeW, Paint()..color = Colors.black87);
    
    // Hair (Dark Cap)
    canvas.drawArc(Rect.fromCenter(center: headPos, width: headR * 2.2, height: headR * 2.2), math.pi, math.pi, true, hairPaint);
  }

  @override bool shouldRepaint(covariant CustomPainter old) => true;
}



class _MatchTopBar extends StatelessWidget {
  final MatchState state;
  const _MatchTopBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildScorePart(name: "LAKERS", score: state.allyScore, color: const Color(0xFF00FF88)),
          const SizedBox(width: 40),
          _buildClockPart(clock: state.timeFormatted, quarter: state.quarter, shotClock: state.shotClock),
          const SizedBox(width: 40),
          _buildScorePart(name: "NETS", score: state.enemyScore, color: const Color(0xFFFF3B30)),
        ],
      ),
    );
  }

  Widget _buildScorePart({required String name, required int score, required Color color}) {
    return Column(
      children: [
        Text(name, style: GoogleFonts.orbitron(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(score.toString().padLeft(2, '0'), style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildClockPart({required String clock, required int quarter, required int shotClock}) {
    return Column(
      children: [
        Text("Q$quarter", style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 12)),
        Text(clock, style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
          child: Text(shotClock.toString(), style: GoogleFonts.shareTechMono(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}


class _TacticalControlBar extends StatelessWidget {
  final ValueChanged<OffensiveTactic> onOffense;
  final ValueChanged<DefensiveTactic> onDefense;
  final OffensiveTactic currentOff;
  final DefensiveTactic currentDef;

  const _TacticalControlBar({required this.onOffense, required this.onDefense, required this.currentOff, required this.currentDef});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black54,
            border: Border(top: BorderSide(color: Colors.white10)),
            gradient: LinearGradient(colors: [Colors.black54, Colors.transparent, Colors.black54], begin: Alignment.centerLeft, end: Alignment.centerRight),
          ),
          child: Row(
            children: [
              _TacticSegment(
                title: "OFFENSE",
                current: currentOff.name.toUpperCase(),
                chips: [
                  _TacticChip(label: "ISO", onSelected: () => onOffense(OffensiveTactic.iso), isSelected: currentOff == OffensiveTactic.iso),
                  _TacticChip(label: "P&R", onSelected: () => onOffense(OffensiveTactic.pickAndRoll), isSelected: currentOff == OffensiveTactic.pickAndRoll),
                  _TacticChip(label: "C&S", onSelected: () => onOffense(OffensiveTactic.catchAndShoot), isSelected: currentOff == OffensiveTactic.catchAndShoot),
                ],
              ),
              const VerticalDivider(color: Colors.white10, width: 60),
              _TacticSegment(
                title: "DEFENSE",
                current: currentDef.name.toUpperCase(),
                chips: [
                  _TacticChip(label: "ZONE", onSelected: () => onDefense(DefensiveTactic.zone), isSelected: currentDef == DefensiveTactic.zone, color: Colors.redAccent),
                  _TacticChip(label: "SWITCH", onSelected: () => onDefense(DefensiveTactic.switchDef), isSelected: currentDef == DefensiveTactic.switchDef, color: Colors.redAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TacticSegment extends StatelessWidget {
  final String title; final String current; final List<Widget> chips;
  const _TacticSegment({required this.title, required this.current, required this.chips});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: GoogleFonts.orbitron(color: Colors.white38, fontSize: 10, letterSpacing: 2)),
              const Spacer(),
              Text(current, style: GoogleFonts.shareTechMono(color: Colors.amberAccent, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: chips.expand((w) => [w, const SizedBox(width: 10)]).toList()..removeLast()),
        ],
      ),
    );
  }
}

class _TacticChip extends StatelessWidget {
  final String label; final VoidCallback onSelected; final bool isSelected; final Color color;
  const _TacticChip({required this.label, required this.onSelected, required this.isSelected, this.color = const Color(0xFF00FF88)});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: isSelected ? color : Colors.white10),
          boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10)] : null,
        ),
        child: Text(label, style: GoogleFonts.orbitron(color: isSelected ? color : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

