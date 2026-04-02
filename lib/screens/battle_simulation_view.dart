import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/glb_model.dart';
import '../models/player.dart';
import '../providers/battle_provider.dart';
import '../widgets/player_card.dart';

// ════════════════════════════════════════════════════════════════════════════
//  Basketball5v5BattleView – Score & Stats Edition
// ════════════════════════════════════════════════════════════════════════════

Offset logicalToIsometric(double x, double y, Size courtSize) {
  final ox = courtSize.width * 0.50;
  final oy = courtSize.height * 0.46;
  final fx = courtSize.width * 0.65;
  final fy = courtSize.height * 0.82;
  final ix = (x - 0.5) * fx - (y - 0.5) * fx;
  final iy = (x - 0.5) * fy * 0.5 + (y - 0.5) * fy * 0.5;
  return Offset(ox + ix, oy + iy);
}

double getScale(double y) => 0.70 + (y * 0.55);

class _Particle {
  Offset position; double radius; final double maxRadius; double alpha; final Color color;
  _Particle({required this.position, required this.color, required this.maxRadius, this.radius = 0.0, this.alpha = 1.0});
  bool get isDead => alpha <= 0;
  void update() { radius += 3.5; alpha = (1.0 - radius / maxRadius).clamp(0.0, 1.0); }
}

class _SimPlayer {
  final GlbModel model; Offset logical; final Offset homeHoop; String anim = 'idle';
  _SimPlayer({required this.model, required this.logical, required this.homeHoop});
}

class Basketball5v5BattleView extends ConsumerStatefulWidget {
  final List<GlbModel> allyModels; final List<GlbModel> enemyModels; final VoidCallback onSkip;
  const Basketball5v5BattleView({super.key, required this.allyModels, required this.enemyModels, required this.onSkip});
  @override ConsumerState<Basketball5v5BattleView> createState() => _Basketball5v5BattleViewState();
}

class _Basketball5v5BattleViewState extends ConsumerState<Basketball5v5BattleView> with TickerProviderStateMixin {
  late final List<_SimPlayer> _allies; late final List<_SimPlayer> _enemies;
  _SimPlayer? _ballHolder; final List<_Particle> _particles = [];
  late final AnimationController _glowCtrl; Timer? _simTimer; double _speedMultiplier = 1.0;
  final List<String> _allyLog = []; final List<String> _enemyLog = [];

  // Score state
  int _allyScore = 0;
  int _enemyScore = 0;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    
    // Tactical mapping for PG, SG, SF, PF, C
    final Map<int, Offset> allyStartMap = {
      0: const Offset(0.5, 0.72), // PG
      1: const Offset(0.3, 0.65), // SG
      2: const Offset(0.7, 0.65), // SF
      3: const Offset(0.38, 0.85), // PF
      4: const Offset(0.62, 0.85), // C
    };
    final Map<int, Offset> enemyStartMap = {
      0: const Offset(0.5, 0.28), // PG
      1: const Offset(0.3, 0.35), // SG
      2: const Offset(0.7, 0.35), // SF
      3: const Offset(0.38, 0.15), // PF
      4: const Offset(0.62, 0.15), // C
    };

    _allies = [for (int i = 0; i < 5; i++) _SimPlayer(model: widget.allyModels[i], logical: allyStartMap[i]!, homeHoop: const Offset(0.5, 0.05))];
    _enemies = [for (int i = 0; i < 5; i++) _SimPlayer(model: widget.enemyModels[i], logical: enemyStartMap[i]!, homeHoop: const Offset(0.5, 0.95))];
    _ballHolder = _allies[0];
    
    // Start battle logic in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(battleProvider.notifier).startBattle();
    });
    
    _startSim();
  }

  @override void dispose() { _simTimer?.cancel(); _glowCtrl.dispose(); super.dispose(); }

  void _startSim() {
    _simTimer?.cancel();
    final ms = (120 / _speedMultiplier).round();
    _simTimer = Timer.periodic(Duration(milliseconds: ms), (_) => mounted ? _tick() : null);
  }

  void _tick() {
    for (final p in _particles) p.update();
    _particles.removeWhere((p) => p.isDead);
    
    // Gate simulation logic during intro
    if (ref.read(battleProvider).isIntro) {
      if (mounted) setState(() {});
      return;
    }
    
    _checkBallOwnership(); _movePlayers(); _checkSkill(); _checkShot();
    if (mounted) setState(() {});
  }

  void _checkBallOwnership() {
    if (math.Random().nextInt((50 / _speedMultiplier).round() + 1) == 0) {
      final same = _ballHolder!.model.team == TeamSide.ally ? _allies : _enemies;
      _ballHolder = same[math.Random().nextInt(same.length)];
    }
  }

  void _movePlayers() {
    final baseSpeed = 0.005 * _speedMultiplier;
    final rng = math.Random();
    
    for (final p in [..._allies, ..._enemies]) {
      Offset goal;
      double speedFactor = 1.0;
      
      if (p == _ballHolder) {
        goal = p.homeHoop;
        // VARIABLE SPEED: Accelerate when driving to the hoop
        final distToHoop = (p.logical - p.homeHoop).distance;
        if (distToHoop < 0.4 && p.anim != 'shoot') {
          p.anim = 'dribble'; 
          speedFactor = 1.5; // "變速切入"
        } else {
          p.anim = 'run';
        }
      } else if (p.model.team != _ballHolder!.model.team) {
        // DEFENSE: Low Stance & Lateral Slide
        final opp = p.model.team == TeamSide.ally ? _enemies : _allies;
        final idx = (alliesIdx(p)) % opp.length;
        goal = opp[idx].logical;
        p.anim = 'defend'; 
        speedFactor = 0.8; // Steady lateral containment
      } else {
        // OFF-BALL: Jab steps or repositioning
        if (rng.nextInt(100) == 0) p.anim = 'idle'; // "試探步" simulation
        goal = Offset(
          (p.logical.dx + (rng.nextDouble() - 0.5) * 0.015).clamp(0.05, 0.95),
          (p.logical.dy + (p.homeHoop.dy - p.logical.dy) * 0.005).clamp(0.05, 0.95)
        );
      }
      
      final actualSpeed = baseSpeed * speedFactor;
      p.logical = Offset(
        p.logical.dx + (goal.dx - p.logical.dx) * actualSpeed,
        p.logical.dy + (goal.dy - p.logical.dy) * actualSpeed
      );
    }
  }
  int alliesIdx(_SimPlayer p) => _allies.contains(p) ? _allies.indexOf(p) : _enemies.indexOf(p);

  void _checkSkill() {
    for (final p in [..._allies, ..._enemies]) {
      if (p.model.grade == PlayerGrade.sClass && math.Random().nextInt((200 / _speedMultiplier).round() + 1) == 0) {
        _triggerSkill(p); break;
      }
    }
  }

  void _triggerSkill(_SimPlayer p) {
    _particles.addAll(List.generate(4, (i) => _Particle(position: p.logical, color: GlbModelLoader.ringColor(p.model.team), maxRadius: 55 + i * 20.0)));
    final log = '[★] ${p.model.name.split(' ').last} 爆發技能！';
    if (p.model.team == TeamSide.ally) _allyLog.insert(0, log); else _enemyLog.insert(0, log);
    ref.read(battleProvider.notifier).simulateLogEntry(p.model.name, 'S 級技能');
  }

  void _checkShot() {
    if (_ballHolder == null) return;
    final dist = (_ballHolder!.logical - _ballHolder!.homeHoop).distance;
    // If close enough to hoop, try a shot
    if (dist < 0.25 && math.Random().nextInt((35 / _speedMultiplier).round() + 1) == 0) {
       _triggerShot(_ballHolder!);
    }
  }

  void _triggerShot(_SimPlayer p) {
    final dist = (p.logical - p.homeHoop).distance;
    final isLayup = dist < 0.12; 
    p.anim = isLayup ? 'layup' : 'shoot'; 
    
    final rng = math.Random();
    // Simplified probability: Power 90+ -> 60% chance, else 40%
    final baseProb = p.model.power >= 90 ? 0.65 : 0.45;
    final success = rng.nextDouble() < baseProb;
    final points = rng.nextDouble() < 0.3 ? 3 : 2; // 30% chance for 3 points

    final logName = p.model.name.split(' ').last;
    
    // Hold the shooting pose briefly
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        if (success) {
          if (p.model.team == TeamSide.ally) {
            _allyScore += points;
            _allyLog.insert(0, '[GOAL] $logName 投籃命中！(+$points)');
          } else {
            _enemyScore += points;
            _enemyLog.insert(0, '[GOAL] $logName 投籃命中！(+$points)');
          }
          // "Score" burst at hoop
          _particles.add(_Particle(position: p.homeHoop, color: Colors.yellowAccent, maxRadius: 80));
        } else {
          final log = '[MISS] $logName 投籃不中...';
          if (p.model.team == TeamSide.ally) _allyLog.insert(0, log); else _enemyLog.insert(0, log);
        }

        // Pass ball to a random opponent after a shot (turnover or rebound)
        final opp = p.model.team == TeamSide.ally ? _enemies : _allies;
        _ballHolder = opp[rng.nextInt(opp.length)];
        p.anim = 'idle';
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final state = ref.watch(battleProvider);

    return RepaintBoundary(
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _IsoCourtPainter())),
          Positioned.fill(child: CustomPaint(painter: _IsoPlayersPainter(
            allies: _allies, enemies: _enemies, ballHolder: _ballHolder, particles: _particles))),
          
          // Scoreboard Top Center
          Positioned(top: 12, left: 0, right: 0, 
            child: Center(child: _ScoreWidget(allyScore: _allyScore, enemyScore: _enemyScore))),

          Positioned(top: 64, left: 12, width: size.width * 0.22, bottom: 64, child: _LogColumn(label: 'TEAM ALLY', color: const Color(0xFF00FF88), logs: _allyLog)),
          Positioned(top: 64, right: 12, width: size.width * 0.22, bottom: 64, child: _LogColumn(label: 'TEAM ENEMY', color: const Color(0xFFFF3B30), logs: _enemyLog)),
          Positioned(bottom: 0, left: 0, right: 0, child: _SpeedBar(current: _speedMultiplier, onSpeed: (s) => setState(() => _speedMultiplier = s), onSkip: widget.onSkip)),

          // 賽前動畫置頂於所有 UI 之上
          if (state.isIntro)
            Positioned.fill(child: _IntroVSOverlay(allyTeam: widget.allyModels, enemyTeam: widget.enemyModels)),
        ],
      ),
    );
  }
}

// ── Scoreboard UI ────────────────────────────────────────────────────────────
class _ScoreWidget extends StatelessWidget {
  final int allyScore; final int enemyScore;
  const _ScoreWidget({required this.allyScore, required this.enemyScore});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _teamScore('ALLY', allyScore, const Color(0xFF00FF88)),
          Container(width: 2, height: 25, color: Colors.white12, margin: const EdgeInsets.symmetric(horizontal: 16)),
          _teamScore('ENEMY', enemyScore, const Color(0xFFFF3B30)),
        ],
      ),
    );
  }

  Widget _teamScore(String label, int score, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.orbitron(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        Text(score.toString().padLeft(2, '0'), style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── Improved Court Painter (NBA Realism) ─────────────────────────────────────
class _IsoCourtPainter extends CustomPainter {
  Offset _i(double x, double y, Size s) => logicalToIsometric(x, y, s);
  @override
  void paint(Canvas canvas, Size size) {
    final s = size;
    canvas.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), Paint()..color = const Color(0xFF060D18));
    final floorPath = Path()..addPolygon([_i(0, 0, s), _i(1, 0, s), _i(1, 1, s), _i(0, 1, s)], true);
    canvas.drawPath(floorPath, Paint()..color = const Color(0xFFBD8E5B));
    final laneP = Paint()..color = const Color(0xFFA57D4E)..style = PaintingStyle.fill;
    _quad(canvas, s, 0, 0, 1, 0.08, laneP); _quad(canvas, s, 0, 0.92, 1, 1, laneP);
    final lineP = Paint()..color = Colors.white..strokeWidth = 2.0..style = PaintingStyle.stroke;
    canvas.drawPath(floorPath, lineP);
    _ln(canvas, s, 0, 0.5, 1, 0.5, lineP);
    _arc(canvas, s, 0.5, 0.5, 0.1, 0.06, 0, 2 * math.pi, lineP);
    _arc(canvas, s, 0.5, 0.94, 0.38, 0.22, math.pi, 2 * math.pi, lineP);
    _arc(canvas, s, 0.5, 0.06, 0.38, 0.22, 0, math.pi, lineP);
    _hoop(canvas, s, 0.5, 0.95, true); _hoop(canvas, s, 0.5, 0.05, false); // Precise 0.05 inset
  }
  void _hoop(Canvas canvas, Size s, double x, double y, bool near) {
    final c = _i(x, y, s); final bW = 44.0; final bH = 30.0; final r = 10.0;
    final bPos = near ? c.translate(0, 18) : c.translate(0, -38);
    canvas.drawLine(bPos.translate(0, 15), bPos.translate(0, 80), Paint()..color = Colors.blueGrey..strokeWidth = 4);
    canvas.drawRect(Rect.fromCenter(center: bPos, width: bW, height: bH), Paint()..color = Colors.white.withValues(alpha: 0.8));
    canvas.drawRect(Rect.fromCenter(center: bPos.translate(0, 2), width: 14, height: 10), Paint()..color = Colors.black..style = PaintingStyle.stroke);
    final rimC = c.translate(0, near ? 6 : -6);
    canvas.drawCircle(rimC, r, Paint()..color = Colors.orange..style = PaintingStyle.stroke..strokeWidth = 2.2);
    _drawNet(canvas, rimC, r);
  }
  void _drawNet(Canvas canvas, Offset rim, double r) {
    final netP = Paint()..color = Colors.white38..strokeWidth = 0.8;
    for (int i = 0; i < 8; i++) {
        final a = i * math.pi / 4; final x = math.cos(a) * r; final y = math.sin(a) * r * 0.5;
        canvas.drawLine(rim + Offset(x, y), rim + Offset(x * 0.6, y + 15), netP);
        canvas.drawLine(rim + Offset(x, y), rim + Offset(math.cos(a + 0.4) * r * 0.6, y + 15), netP);
    }
  }
  void _quad(Canvas c, Size s, double x0, double y0, double x1, double y1, Paint p) => c.drawPath(Path()..addPolygon([_i(x0, y0, s), _i(x1, y0, s), _i(x1, y1, s), _i(x0, y1, s)], true), p);
  void _ln(Canvas c, Size s, double x0, double y0, double x1, double y1, Paint p) => c.drawLine(_i(x0, y0, s), _i(x1, y1, s), p);
  void _arc(Canvas c, Size s, double cx, double cy, double rx, double ry, double a0, double a1, Paint p) {
    final path = Path();
    for (int i = 0; i <= 32; i++) {
      final a = a0 + (a1 - a0) * i / 32; final pt = _i(cx + rx * math.cos(a), cy + ry * math.sin(a), s);
      if (i == 0) path.moveTo(pt.dx, pt.dy); else path.lineTo(pt.dx, pt.dy);
    }
    c.drawPath(path, p);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Segmented Humanoid Sprite Painter ────────────────────────────────────────
class _IsoPlayersPainter extends CustomPainter {
  final List<_SimPlayer> allies; final List<_SimPlayer> enemies;
  final _SimPlayer? ballHolder; final List<_Particle> particles;
  _IsoPlayersPainter({required this.allies, required this.enemies, required this.ballHolder, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    Offset iso(double x, double y) => logicalToIsometric(x, y, size);
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    for (final pt in particles) {
      final c = iso(pt.position.dx, pt.position.dy);
      canvas.drawCircle(c, pt.radius, Paint()..color = pt.color.withValues(alpha: pt.alpha)..style = PaintingStyle.stroke..strokeWidth = 2.0);
    }
    final all = [...allies, ...enemies]..sort((a, b) => a.logical.dy.compareTo(b.logical.dy));
    for (final p in all) {
      final pos = iso(p.logical.dx, p.logical.dy);
      final scale = getScale(p.logical.dy);
      final color = GlbModelLoader.ringColor(p.model.team);
      final swing = p.anim == 'run' ? math.sin(time * 15.0) : 0.0;
      _drawSegmentedHuman(canvas, pos, scale, color, p.model.jerseyNumber, swing, p.anim);
      if (p == ballHolder) {
        final bY = -35.0 * scale + math.sin(time * 20.0).abs() * 12.0 * scale;
        canvas.drawCircle(pos.translate(22 * scale, bY), 5 * scale, Paint()..color = Colors.orange);
      }
      final tp = TextPainter(text: TextSpan(text: p.model.name.split(' ').last, style: TextStyle(color: Colors.white, fontSize: 8 * scale, fontWeight: FontWeight.bold, shadows: const [Shadow(blurRadius: 3, color: Colors.black)])), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, pos.translate(-tp.width / 2, 8 * scale));
    }
  }
  void _drawSegmentedHuman(Canvas canvas, Offset base, double sc, Color teamC, String num, double swing, String anim) {
    final skinColor = const Color(0xFFFFDBAC);
    final hairColor = const Color(0xFF2D1B13);
    final isAlly = teamC == const Color(0xFF00FF88);

    // POSTURE: Lower center of gravity for defense and dribbling
    final isLowStance = anim == 'defend' || anim == 'dribble';
    final isLayup = anim == 'layup';
    final isShooting = anim == 'shoot';

    // Vertical lift for jump shots and layups
    final liftY = (isShooting || isLayup) ? -8.0 * sc : 0.0;
    final crouchY = isLowStance ? 4.0 * sc : liftY;
    
    // Shadow
    canvas.drawOval(Rect.fromCenter(center: base, width: 26 * sc, height: 10 * sc), Paint()..color = Colors.black26);
    
    final headR = 7.0 * sc; 
    final torsoW = 20.0 * sc; 
    final torsoH = 26.0 * sc; 
    final limbW = 5.5 * sc; 
    final upperL = 10.0 * sc; 
    final lowerL = 10.0 * sc;

    // LEGS: Split into Thigh & Calf
    void drawLeg(double sideOffset, double phase, bool isLifted) {
      final hip = base.translate(sideOffset * sc, -20 * sc + crouchY);
      
      double kneeAngle;
      double currentPhase = phase;
      
      if (isLifted) {
        currentPhase = -math.pi / 2.5; // Lift thigh high
        kneeAngle = -math.pi / 2;     // Bend calf back sharply
      } else {
        kneeAngle = - (0.3 + (phase.abs() * 0.5) + (isLowStance ? 0.3 : 0.0));
      }
      
      final upperEnd = hip.translate(math.sin(currentPhase) * upperL, math.cos(currentPhase) * upperL);
      final lowerEnd = upperEnd.translate(math.sin(currentPhase + kneeAngle) * lowerL, math.cos(currentPhase + kneeAngle) * lowerL);
      
      _line(canvas, hip, upperEnd, limbW, skinColor);
      _line(canvas, upperEnd, lowerEnd, limbW * 0.85, skinColor);
    }
    
    // During layup, lift the "inside" leg (simplified as one specific leg)
    drawLeg(-6, swing, isLayup); 
    drawLeg(6, -swing, false);

    // TORSO (Jersey)
    final torsoCenter = base.translate(0, -20 * sc - torsoH / 2 + crouchY);
    final torsoRect = Rect.fromCenter(center: torsoCenter, width: torsoW, height: torsoH);
    canvas.drawRRect(RRect.fromRectAndRadius(torsoRect, Radius.circular(5 * sc)), Paint()..color = teamC);

    // Jersey Number
    final jColor = isAlly ? Colors.black : Colors.white;
    final nt = TextPainter(text: TextSpan(text: num, style: TextStyle(color: jColor, fontSize: 13 * sc, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
    nt.paint(canvas, torsoRect.center - Offset(nt.width / 2, nt.height / 2));

    // ARMS: Split into Upper Arm & Forearm
    void drawArm(double sideOffset, double phase, bool activeShooting, bool layupArm) {
      final shoulder = base.translate(sideOffset * sc, -20 * sc - torsoH + 6 * sc + crouchY);
      
      double armAngle;
      double elbowAngle;
      
      if (activeShooting) {
        armAngle = -math.pi * 0.8;
        elbowAngle = -math.pi / 4;
      } else if (layupArm) {
        armAngle = -math.pi * 0.7; // Reach forward and up
        elbowAngle = -0.1;          // Nearly straight arm
      } else {
        armAngle = (phase + math.pi / 4);
        elbowAngle = math.pi / 2.5;
      }
      
      final elbow = shoulder.translate(math.sin(armAngle) * 9 * sc, math.cos(armAngle) * 9 * sc);
      final hand = elbow.translate(math.sin(armAngle + elbowAngle) * 8 * sc, math.cos(armAngle + elbowAngle) * 8 * sc);
      
      _line(canvas, shoulder, elbow, limbW * 0.8, skinColor);
      _line(canvas, elbow, hand, limbW * 0.7, skinColor);
    }
    
    drawArm(-11, -swing * 0.6, isShooting, isLayup); // Left arm reaches during layup
    drawArm(11, swing * 0.6, isShooting, false);

    // HEAD
    final headPos = base.translate(0, -20 * sc - torsoH - headR + crouchY);
    canvas.drawCircle(headPos, headR, Paint()..color = skinColor);
    
    // Eyes: Looking towards the hoop
    final eyeYOffset = isAlly ? -2.5 * sc : 2.5 * sc;
    final eyeW = 1.2 * sc;
    canvas.drawCircle(headPos.translate(-2.5 * sc, eyeYOffset), eyeW, Paint()..color = Colors.black87);
    canvas.drawCircle(headPos.translate(2.5 * sc, eyeYOffset), eyeW, Paint()..color = Colors.black87);
    
    // Hair
    canvas.drawArc(Rect.fromCenter(center: headPos, width: headR * 2.2, height: headR * 2.2), math.pi, math.pi, true, Paint()..color = hairColor);
  }

  void _line(Canvas canvas, Offset start, Offset end, double width, Color color) {
    canvas.drawLine(start, end, Paint()..color = color..strokeWidth = width..strokeCap = StrokeCap.round);
  }
  @override bool shouldRepaint(covariant _IsoPlayersPainter old) => true;
}

class _LogColumn extends StatelessWidget {
  final String label; final Color color; final List<String> logs;
  const _LogColumn({required this.label, required this.color, required this.logs});
  @override Widget build(BuildContext context) {
    return Container(decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.4))),
      child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(label, style: GoogleFonts.orbitron(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
        const Divider(color: Colors.white10, height: 1),
        Expanded(child: ListView.builder(reverse: true, itemCount: logs.length, itemBuilder: (_, i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(logs[i], style: GoogleFonts.shareTechMono(color: logs[i].contains('GOAL') ? Colors.amberAccent : color, fontSize: 11.5)))))
      ]));
  }
}

class _SpeedBar extends StatelessWidget {
  final double current; final ValueChanged<double> onSpeed; final VoidCallback onSkip;
  const _SpeedBar({required this.current, required this.onSpeed, required this.onSkip});
  @override Widget build(BuildContext context) {
    return Container(height: 52, padding: const EdgeInsets.symmetric(horizontal: 16), color: const Color(0xFF0D1117),
      child: Row(children: [
        _btn('1×', 1.0), const SizedBox(width: 8), _btn('1.5×', 1.5), const SizedBox(width: 8), _btn('2×', 2.0),
        const Spacer(), ElevatedButton(onPressed: onSkip, style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
          child: Text('SKIP / 跳過', style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 12))),
      ]));
  }
  Widget _btn(String l, double v) {
    final s = current == v;
    return GestureDetector(onTap: () => onSpeed(v), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: s ? Colors.green : Colors.grey), color: s ? Colors.green.withValues(alpha: 0.1) : null),
      child: Text(l, style: GoogleFonts.orbitron(color: s ? Colors.green : Colors.grey, fontSize: 11))));
  }
}
class _IntroVSOverlay extends StatefulWidget {
  final List<GlbModel> allyTeam;
  final List<GlbModel> enemyTeam;
  const _IntroVSOverlay({required this.allyTeam, required this.enemyTeam});

  @override
  State<_IntroVSOverlay> createState() => _IntroVSOverlayState();
}

class _IntroVSOverlayState extends State<_IntroVSOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slideAnim;
  late final Animation<double> _vsAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _slideAnim = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic));
    _vsAnim = CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1.0, curve: Curves.elasticOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 動態背景粒子或裝飾可以在這裡加
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // ALLY TEAM (Left side)
                Expanded(
                  child: AnimatedBuilder(
                    animation: _slideAnim,
                    builder: (context, child) {
                      final offset = (1.0 - _slideAnim.value) * -size.width * 0.5;
                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: child,
                      );
                    },
                    child: _buildCardRow(widget.allyTeam, isAlly: true),
                  ),
                ),

                // VS SECTION
                SizedBox(
                  width: 80, // 縮小 VS 寬度
                  child: Center(
                    child: ScaleTransition(
                      scale: _vsAnim,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            "VS",
                            style: GoogleFonts.orbitron(
                              fontSize: 80,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 2
                                ..color = Colors.white24,
                            ),
                          ),
                          Text(
                            "VS",
                            style: GoogleFonts.orbitron(
                              fontSize: 78,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Colors.cyanAccent.withValues(alpha: 0.5), blurRadius: 20),
                                Shadow(color: Colors.redAccent.withValues(alpha: 0.5), blurRadius: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ENEMY TEAM (Right side)
                Expanded(
                  child: AnimatedBuilder(
                    animation: _slideAnim,
                    builder: (context, child) {
                      final offset = (1.0 - _slideAnim.value) * size.width * 0.5;
                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: child,
                      );
                    },
                    child: _buildCardRow(widget.enemyTeam, isAlly: false),
                  ),
                ),
              ],
            ),
          ),
          
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _vsAnim,
                child: Text(
                  "ANALYZING TEAM SYNERGY...",
                  style: GoogleFonts.orbitron(
                    color: Colors.white24,
                    fontSize: 12,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardRow(List<GlbModel> team, {required bool isAlly}) {
    final cardWidth = 60.0; // 進一步縮小
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            isAlly ? "MY SQUAD" : "OPPONENTS",
            style: GoogleFonts.orbitron(
              color: isAlly ? const Color(0xFF00FF88) : const Color(0xFFFF3B30),
              fontSize: 18, // 稍微縮小字體
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 16), // 縮小間距
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(team.length, (i) {
              final glb = team[i];
              final card = PlayerCard(
                id: glb.id,
                name: glb.name.split(' ').last,
                team: isAlly ? "Ally" : "Enemy",
                position: _idxToPos(i),
                baseScore: glb.power,
                rarity: _gradeToRarity(glb.grade),
              );

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2), // 稍微間隔
                child: Hero(
                  tag: 'battle_card_${glb.id}',
                  child: PlayerCardWidget(
                    player: card,
                    width: cardWidth,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  String _idxToPos(int i) {
    switch (i) {
      case 0: return "PG";
      case 1: return "SG";
      case 2: return "SF";
      case 3: return "PF";
      case 4: return "C";
      default: return "?";
    }
  }

  Rarity _gradeToRarity(PlayerGrade grade) {
    switch (grade) {
      case PlayerGrade.sClass: return Rarity.S;
      case PlayerGrade.aClass: return Rarity.A;
      case PlayerGrade.bClass: return Rarity.B;
    }
  }
}
