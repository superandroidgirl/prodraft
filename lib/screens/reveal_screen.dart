import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';
import '../widgets/player_card.dart';
import 'card_detail_screen.dart';

class RevealScreen extends StatefulWidget {
  final List<PlayerCard> players;
  final String packImagePath;

  const RevealScreen({
    super.key,
    required this.players,
    required this.packImagePath,
  });

  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen>
    with TickerProviderStateMixin {
  // ── Tear Animation States ──
  bool _isTorn = false;
  double _dragProgress = 0.0;
  late AnimationController _tearAnimController;

  // ── Card Reveal States ──
  late List<AnimationController> _flipControllers;
  final List<bool> _revealed = [];
  bool _showSRankOverlay = false;
  int _currentSRankIndex = -1;
  bool _allRevealed = false;

  late AnimationController _flashController;
  late Animation<double> _flashAnim;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();

    // 1. Tear animation setup
    _tearAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _tearAnimController.addListener(() {
      setState(() {
        _dragProgress = _tearAnimController.value;
      });
    });

    // 2. Regular reveal setup
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _flashAnim = CurvedAnimation(parent: _flashController, curve: Curves.easeOut);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _flipControllers = List.generate(
      widget.players.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );

    for (int i = 0; i < widget.players.length; i++) {
      _revealed.add(false);
    }
  }

  @override
  void dispose() {
    _tearAnimController.dispose();
    for (final c in _flipControllers) {
      c.dispose();
    }
    _flashController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _onTearComplete() {
    if (_isTorn) return;
    _tearAnimController.value = _dragProgress;
    _tearAnimController.animateTo(1.0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);

    // Flash white then toggle torn state & begin revealing cards
    _flashController.forward().then((_) {
      if (mounted) {
        setState(() {
          _isTorn = true;
        });
        _flashController.reverse(); // fade out flash
        _startRevealSequence();
      }
    });
  }

  Future<void> _startRevealSequence() async {
    await Future.delayed(const Duration(milliseconds: 600));
    for (int i = 0; i < widget.players.length; i++) {
      final player = widget.players[i];

      if (player.rarity == Rarity.S) {
        setState(() {
          _showSRankOverlay = true;
          _currentSRankIndex = i;
        });
        _flashController.forward();
        _triggerVibration();
        await Future.delayed(const Duration(milliseconds: 1800));
        _flashController.reverse();
        setState(() {
          _showSRankOverlay = false;
          _currentSRankIndex = -1;
        });
      }

      await _flipControllers[i].forward();
      setState(() => _revealed[i] = true);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    setState(() => _allRevealed = true);
  }

  Future<void> _triggerVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(pattern: [0, 150, 100, 300, 100, 150]);
      }
    } catch (_) {}
  }

  void _revealAll() {
    for (int i = 0; i < widget.players.length; i++) {
      if (!_revealed[i]) {
        _flipControllers[i].forward();
        _revealed[i] = true;
      }
    }
    setState(() {
      _showSRankOverlay = false;
      _allRevealed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isTorn) {
      return _buildTearingPhase();
    }
    return _buildRevealPhase();
  }

  // ============== 1. TEARING PHASE ==============
  Widget _buildTearingPhase() {
    final progress = _dragProgress;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background stars
          Positioned.fill(
            child: Image.asset(
              'assets/images/stars_bg.png',
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.45),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isTorn) return;
                    final screenWidth = MediaQuery.of(context).size.width;
                    _dragProgress += details.delta.dx / (screenWidth * 0.6);
                    _dragProgress = _dragProgress.clamp(0.0, 1.0);
                    setState(() {});

                    if (_dragProgress >= 0.85) {
                      _onTearComplete();
                    }
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isTorn) return;
                    if (_dragProgress < 0.85) {
                      _tearAnimController.value = _dragProgress;
                      _tearAnimController.animateTo(0.0,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut);
                    }
                  },
                  child: SizedBox(
                    width: 300,
                    height: 440,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Inner Glow (Backside or card silhouette)
                        Opacity(
                          opacity: (progress > 0.3 ? ((progress - 0.3) / 0.7) : 0)
                              .toDouble()
                              .clamp(0.0, 1.0),
                          child: Container(
                            width: 180,
                            height: 270,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.amber.withValues(alpha: 0.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.8),
                                  blurRadius: 50 + progress * 60,
                                  spreadRadius: 8 + progress * 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Pack Bottom Part (shakes slightly if dragging)
                        Transform.translate(
                          offset: Offset(
                            progress > 0.5 ? math.sin(progress * 30) * 2 : 0,
                            progress > 0.5 ? math.cos(progress * 20) * 1 : 0,
                          ),
                          child: ClipPath(
                            clipper: PackBottomClipper(),
                            child: Image.asset(
                              widget.packImagePath,
                              width: 280,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        // Pack Top Part (tears away)
                        Transform.translate(
                          offset: Offset(
                            progress * 500 * Curves.easeIn.transform(progress),
                            -progress * 150 * Curves.easeIn.transform(progress),
                          ),
                          child: Transform.rotate(
                            angle: progress * 0.35,
                            child: Opacity(
                              opacity: (1.0 - progress * 1.2).clamp(0.0, 1.0),
                              child: ClipPath(
                                clipper: PackTopClipper(),
                                child: Image.asset(
                                  widget.packImagePath,
                                  width: 280,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Particle debris triggers at progress > 0.3
                        if (progress > 0.3 && progress < 1.0)
                          ..._buildTearParticles(progress),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: progress < 0.1 ? 1.0 : (1.0 - progress).clamp(0.0, 1.0),
                  child: Text(
                    "← 滑動撕開卡包 →",
                    style: GoogleFonts.oswald(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // White Flash overlay
          AnimatedBuilder(
            animation: _flashController,
            builder: (context, child) {
              final v = _flashController.value;
              final opacity = v < 0.5 ? (v * 2).clamp(0.0, 1.0) : ((1.0 - v) * 2).clamp(0.0, 1.0);
              return IgnorePointer(
                child: Container(
                  color: Colors.white.withValues(alpha: opacity * 0.9),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTearParticles(double progress) {
    final random = math.Random(42);
    return List.generate(15, (i) {
      final startX = 140.0 + random.nextDouble() * 20;
      final startY = 120.0 + random.nextDouble() * 30;
      final dx = (random.nextDouble() - 0.2) * 180 * progress;
      final dy = (random.nextDouble() - 0.6) * 120 * progress;
      final size = 2.0 + random.nextDouble() * 3;
      final opacity = ((1.0 - progress) * 1.5).clamp(0.0, 0.8);
      return Positioned(
        left: startX + dx,
        top: startY + dy,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      );
    });
  }

  // ============== 2. REVEAL PHASE ==============
  Widget _buildRevealPhase() {
    final isSingle = widget.players.length == 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/stars_bg.png',
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.45),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          ..._buildParticleDecorations(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                Expanded(
                  child: isSingle ? _buildSingleReveal() : _buildGridReveal(),
                ),
                _buildFooterButtons(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_showSRankOverlay) _buildSRankOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            widget.players.length == 1 ? '單抽結果' : '十連抽結果',
            style: GoogleFonts.oswald(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          if (!_allRevealed)
            TextButton(
              onPressed: _revealAll,
              child: Text(
                '全部翻開',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            const SizedBox(width: 70),
        ],
      ),
    );
  }

  Widget _buildSingleReveal() {
    final player = widget.players[0];
    final heroTag = 'card_reveal_${player.id}';
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _revealed[0]
                  ? () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          opaque: false,
                          pageBuilder: (_, __, ___) => CardDetailScreen(
                            player: player,
                            heroTag: heroTag,
                          ),
                          transitionsBuilder:
                              (_, animation, __, child) => FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                          transitionDuration: const Duration(milliseconds: 400),
                        ),
                      )
                  : null,
              child: Hero(
                tag: heroTag,
                child: _FlipCard(
                  controller: _flipControllers[0],
                  player: player,
                  width: 200,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_revealed[0]) ...[
              Text(
                player.name,
                style: GoogleFonts.oswald(
                  fontSize: 24,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '點擊卡片查看詳情',
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 6),
              _buildRarityRow(player),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGridReveal() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 3 / 4,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: List.generate(widget.players.length, (i) {
          final player = widget.players[i];
          final heroTag = 'card_reveal_${player.id}_$i';
          return GestureDetector(
            onTap: _revealed[i]
                ? () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, __, ___) => CardDetailScreen(
                          player: player,
                          heroTag: heroTag,
                        ),
                        transitionsBuilder:
                            (_, animation, __, child) => FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                        transitionDuration: const Duration(milliseconds: 400),
                      ),
                    )
                : _allRevealed
                    ? null
                    : _revealAll,
            child: Hero(
              tag: heroTag,
              child: _FlipCard(
                controller: _flipControllers[i],
                player: player,
                width: 64,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRarityRow(PlayerCard player) {
    final color = _rarityColor(player.rarity);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color),
          ),
          child: Text(
            '${player.rarityLabel} 級  •  ${player.position}  •  ${player.team}',
            style: GoogleFonts.oswald(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '確定',
                    style: GoogleFonts.oswald(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSRankOverlay() {
    return AnimatedBuilder(
      animation: _flashAnim,
      builder: (_, __) {
        return Stack(
          children: [
            Container(
              color: Colors.black.withValues(alpha: 0.85 * _flashAnim.value),
            ),
            Positioned.fill(
              child: RotationTransition(
                turns: _rotateController,
                child: CustomPaint(
                  painter: _GoldParticlePainter(_flashAnim.value),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '✨',
                    style: TextStyle(
                      fontSize: 60 * _flashAnim.value,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.goldGradient.createShader(bounds),
                    child: Text(
                      'S 級降臨！',
                      style: GoogleFonts.oswald(
                        fontSize: 42 * _flashAnim.value,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_currentSRankIndex >= 0 &&
                      _currentSRankIndex < widget.players.length)
                    Text(
                      widget.players[_currentSRankIndex].name,
                      style: GoogleFonts.roboto(
                        fontSize: 18 * _flashAnim.value,
                        color: AppColors.secondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildParticleDecorations() {
    return [
      Positioned(
        top: -60,
        right: -40,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.06),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: -80,
        left: -60,
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.secondary.withValues(alpha: 0.05),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Color _rarityColor(Rarity r) {
    switch (r) {
      case Rarity.C:
        return AppColors.rarityC;
      case Rarity.B:
        return AppColors.rarityB;
      case Rarity.A:
        return AppColors.rarityA;
      case Rarity.S:
        return AppColors.rarityS;
    }
  }
}

// ──────────────────────────────────────────────────────
// FlipCard widget - Y-axis flip animation
// ──────────────────────────────────────────────────────
class _FlipCard extends StatelessWidget {
  final AnimationController controller;
  final PlayerCard player;
  final double width;

  const _FlipCard({
    required this.controller,
    required this.player,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    return AnimatedBuilder(
      animation: flipAnim,
      builder: (_, __) {
        final value = flipAnim.value;
        final isFront = value >= 0.5;
        final angle = isFront ? (value - 1) * 3.14159 : value * 3.14159;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: isFront
              ? PlayerCardWidget(player: player, width: width)
              : _CardBack(width: width),
        );
      },
    );
  }
}

class _CardBack extends StatelessWidget {
  final double width;
  const _CardBack({required this.width});

  @override
  Widget build(BuildContext context) {
    final height = width * 4 / 3;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/card_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Image.asset(
            'assets/images/card_border.png',
            fit: BoxFit.fill,
          ),
          Center(
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient.createShader(bounds),
              child: Icon(
                Icons.sports_basketball,
                color: Colors.white,
                size: width * 0.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Gold particle painter for S-rank overlay
class _GoldParticlePainter extends CustomPainter {
  final double progress;
  _GoldParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 24; i++) {
      final angle = (i / 24) * 3.14159 * 2;
      final length = size.height * 0.5 * progress;
      final opacity = progress * 0.4;

      paint.shader = LinearGradient(
        colors: [
          const Color(0xFFFFD700).withValues(alpha: opacity),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCenter(
          center: Offset(
            center.dx + (length / 2) * (angle < 3.14159 ? 1 : -1),
            center.dy,
          ),
          width: 2,
          height: length,
        ),
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(0, -length / 2),
          width: 2,
          height: length,
        ),
        paint,
      );
      canvas.restore();
    }

    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFFFD700).withValues(alpha: 0.3 * progress),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: center, radius: 150 * progress));
    canvas.drawCircle(center, 150 * progress, paint);
  }

  @override
  bool shouldRepaint(_GoldParticlePainter old) => old.progress != progress;
}

// ──────────────────────────────────────────────────────
// Custom Clippers for Tearing Effect
// ──────────────────────────────────────────────────────

// Clips the TOP portion of the pack (the part that tears away)
class PackTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final tearY = size.height * 0.32; // Higher rip line
    path.moveTo(0, 0);
    path.lineTo(0, tearY);
    
    // Jagged tear line
    final segments = 16;
    for (int i = 0; i <= segments; i++) {
      final x = (size.width / segments) * i;
      final noise = math.sin(i * 2.5) * 8 + math.cos(i * 4) * 4;
      path.lineTo(x, tearY + noise);
    }
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Clips the BOTTOM portion of the pack (stays in place)
class PackBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final tearY = size.height * 0.32;
    path.moveTo(0, tearY);
    
    final segments = 16;
    for (int i = 0; i <= segments; i++) {
      final x = (size.width / segments) * i;
      final noise = math.sin(i * 2.5) * 8 + math.cos(i * 4) * 4;
      path.lineTo(x, tearY + noise);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
