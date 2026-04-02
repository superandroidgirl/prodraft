import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';
import '../widgets/player_card.dart';

class CardDetailScreen extends StatefulWidget {
  final PlayerCard player;
  final String heroTag;

  const CardDetailScreen({
    super.key,
    required this.player,
    required this.heroTag,
  });

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _infoController;
  late Animation<double> _infoFade;
  late Animation<Offset> _infoSlide;

  @override
  void initState() {
    super.initState();
    _infoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _infoFade = CurvedAnimation(
      parent: _infoController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    _infoSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _infoController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    // Start after Hero settles
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _infoController.forward();
    });
  }

  @override
  void dispose() {
    _infoController.dispose();
    super.dispose();
  }

  Color get _rarityColor {
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Background: blue_mist from sorare ──
          Positioned.fill(
            child: Image.asset(
              'assets/images/blue_mist_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Dark overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Back button ──
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                // ── Hero Card (centered, larger) ──
                Expanded(
                  flex: 6,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: AspectRatio(
                        aspectRatio: 0.68,
                        child: Hero(
                          tag: widget.heroTag,
                          child: PlayerCardWidget(
                            player: widget.player,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Player info panel (slides in) ──
                Expanded(
                  flex: 5,
                  child: FadeTransition(
                    opacity: _infoFade,
                    child: SlideTransition(
                      position: _infoSlide,
                      child: _buildInfoPanel(context),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + Rarity badge
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.player.name,
                  style: GoogleFonts.oswald(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
              _RarityBadgeLarge(
                rarity: widget.player.rarity,
                color: _rarityColor,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.player.position}  ·  ${widget.player.team}',
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: Colors.white60,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  label: '基礎分',
                  value: widget.player.baseScore.toStringAsFixed(1),
                  color: _rarityColor,
                ),
              ),
              Expanded(
                child: _StatCell(
                  label: '加成',
                  value:
                      '×${widget.player.bonusMultiplier.toStringAsFixed(2)}',
                  color: AppColors.secondary,
                ),
              ),
              Expanded(
                child: _StatCell(
                  label: '總積分',
                  value: widget.player.totalScore.toStringAsFixed(1),
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.favorite_border,
                  label: '收藏',
                  color: Colors.pinkAccent,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.swap_horiz,
                  label: '上陣',
                  color: AppColors.primary,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.sell_outlined,
                  label: '出售',
                  color: AppColors.secondary,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// Helper sub-widgets
// ──────────────────────────────────────────────────────

class _RarityBadgeLarge extends StatelessWidget {
  final Rarity rarity;
  final Color color;
  const _RarityBadgeLarge({required this.rarity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Text(
        rarity.name.toUpperCase(),
        style: GoogleFonts.oswald(
          fontSize: 16,
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCell(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.oswald(
            fontSize: 22,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 11,
            color: Colors.white54,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.oswald(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
