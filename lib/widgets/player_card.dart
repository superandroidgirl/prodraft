import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';

class PlayerCardWidget extends StatefulWidget {
  final PlayerCard player;
  final bool faceDown;
  final VoidCallback? onTap;
  final double width;

  const PlayerCardWidget({
    super.key,
    required this.player,
    this.faceDown = false,
    this.onTap,
    this.width = 100,
  });

  @override
  State<PlayerCardWidget> createState() => _PlayerCardWidgetState();
}

class _PlayerCardWidgetState extends State<PlayerCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Color get _rarityTint {
    switch (widget.player.rarity) {
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.hasBoundedWidth 
            ? constraints.maxWidth 
            : widget.width;
        final double height = width * 1.27;

        if (widget.faceDown) {
          return _buildCardBack(width, height);
        }

        final isS = widget.player.rarity == Rarity.S;
        final cardWidget = _buildCardFront(width, height);

        if (isS) {
          return AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              final val = _shimmerController.value;
              final pulse = (1 + math.sin(val * math.pi * 2)) / 2; // 0.0 ~ 1.0
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.rarityS.withOpacity(0.2 + 0.35 * pulse),
                      blurRadius: 15 + 15 * pulse,
                      spreadRadius: 2 + 5 * pulse,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: GestureDetector(
              onTap: widget.onTap,
              child: cardWidget,
            ),
          );
        }

        return GestureDetector(
          onTap: widget.onTap,
          child: cardWidget,
        );
      },
    );
  }

  Widget _buildCardBack(double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Mist background
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/card_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Card border overlay
          Image.asset(
            'assets/images/card_border.png',
            fit: BoxFit.fill,
          ),
          // ProDraft logo centre
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

  Widget _buildCardFront(double width, double height) {
    final isS = widget.player.rarity == Rarity.S;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Layer 1: card_bg (mist) tinted by rarity ──
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  _rarityTint.withOpacity(0.25),
                  BlendMode.srcATop,
                ),
                child: Image.asset(
                  'assets/images/card_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // ── Layer 2: player cutout (overflowing top) ──
          if (widget.player.imagePath != null)
            Positioned(
              left: 0,
              right: 0,
              // Overflow the card top by 15% of height for the "立繪超框" effect
              top: -(height * 0.15),
              bottom: height * 0.12,
              child: Image.asset(
                widget.player.imagePath!,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),

          // ── Layer 3: gradient footer overlay ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: height * 0.38,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(10),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 4: card_border frame ──
          Positioned.fill(
            child: Image.asset(
              'assets/images/card_border.png',
              fit: BoxFit.fill,
              color: _rarityTint.withOpacity(0.5),
              colorBlendMode: BlendMode.srcATop,
            ),
          ),

          // ── Layer 5: rarity badge (top-left) ──
          Positioned(
            top: 6,
            left: 8,
            child: _RarityBadge(rarity: widget.player.rarity, color: _rarityTint),
          ),

          // ── Layer 6: team label (top-right) ──
          Positioned(
            top: 6,
            right: 8,
            child: Text(
              widget.player.team,
              style: GoogleFonts.oswald(
                fontSize: width * 0.10,
                color: _rarityTint,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),

          // ── Layer 7: player info footer ──
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.player.name,
                  style: GoogleFonts.oswald(
                    fontSize: width * 0.115,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.player.position,
                      style: GoogleFonts.roboto(
                        fontSize: width * 0.09,
                        color: Colors.white70,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                    _ScorePill(
                      score: widget.player.totalScore,
                      color: _rarityTint,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Layer 8: S-rank shimmer sweep ──
          if (isS)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (_, __) => CustomPaint(
                    painter: _SweepShimmerPainter(
                      _shimmerController.value,
                      AppColors.rarityS,
                    ),
                  ),
                ),
              ),
            ),



          // ── Layer 9: outer glow box shadow ──
          // (handled via Container decoration below)
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// Helper sub-widgets
// ──────────────────────────────────────────────────────

class _RarityBadge extends StatelessWidget {
  final Rarity rarity;
  final Color color;
  const _RarityBadge({required this.rarity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        rarity.name.toUpperCase(),
        style: GoogleFonts.oswald(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final double score;
  final Color color;
  const _ScorePill({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        score.toStringAsFixed(1),
        style: GoogleFonts.oswald(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Diagonal sweep shimmer painter
class _SweepShimmerPainter extends CustomPainter {
  final double progress;
  final Color tintColor;
  _SweepShimmerPainter(this.progress, this.tintColor);

  @override
  void paint(Canvas canvas, Size size) {
    final sweepX = size.width * (-0.5 + progress * 2.0);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          tintColor.withOpacity(0.35),
          Colors.white.withOpacity(0.6),
          tintColor.withOpacity(0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(
        Rect.fromCenter(
          center: Offset(sweepX, size.height / 2),
          width: size.width * 0.5,
          height: size.height,
        ),
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_SweepShimmerPainter old) =>
      old.progress != progress || old.tintColor != tintColor;
}
