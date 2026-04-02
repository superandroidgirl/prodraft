import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/manager.dart';
import '../theme/app_theme.dart';

class RankBadge extends StatefulWidget {
  final ManagerRank rank;
  final double size;
  final bool showLabel;

  const RankBadge({
    super.key,
    required this.rank,
    this.size = 80,
    this.showLabel = true,
  });

  @override
  State<RankBadge> createState() => _RankBadgeState();
}

class _RankBadgeState extends State<RankBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.rank == ManagerRank.legendary) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _primaryColor {
    switch (widget.rank) {
      case ManagerRank.bronze:
        return AppColors.rankBronze;
      case ManagerRank.silver:
        return AppColors.rankSilver;
      case ManagerRank.gold:
        return AppColors.rankGold;
      case ManagerRank.platinum:
        return AppColors.rankPlatinum;
      case ManagerRank.diamond:
        return AppColors.rankDiamond;
      case ManagerRank.legendary:
        return AppColors.rankLegendary;
    }
  }


  String get _emoji {
    switch (widget.rank) {
      case ManagerRank.bronze:
        return '🥉';
      case ManagerRank.silver:
        return '🥈';
      case ManagerRank.gold:
        return '🥇';
      case ManagerRank.platinum:
        return '💠';
      case ManagerRank.diamond:
        return '💎';
      case ManagerRank.legendary:
        return '👑';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) {
            return Transform.scale(
              scale: widget.rank == ManagerRank.legendary
                  ? _pulseAnim.value
                  : 1.0,
              child: child,
            );
          },
          child: _buildBadge(),
        ),
        if (widget.showLabel) ...[
          const SizedBox(height: 8),
          Text(
            _rankLabel,
            style: GoogleFonts.oswald(
              fontSize: 13,
              color: _primaryColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBadge() {
    final isLegendary = widget.rank == ManagerRank.legendary;
    final isDiamond = widget.rank == ManagerRank.diamond ||
        widget.rank == ManagerRank.platinum;
    final size = widget.size;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: isDiamond ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isDiamond ? BorderRadius.circular(10) : null,
        gradient: RadialGradient(
          colors: [
            _primaryColor.withValues(alpha: 0.4),
            _primaryColor.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: _primaryColor,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: isLegendary ? 0.7 : 0.3),
            blurRadius: isLegendary ? 24 : 12,
            spreadRadius: isLegendary ? 4 : 1,
          ),
        ],
      ),
      child: Center(
        child: isLegendary
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _emoji,
                    style: TextStyle(fontSize: size * 0.35),
                  ),
                  Icon(
                    Icons.local_fire_department,
                    color: AppColors.rankLegendary,
                    size: size * 0.22,
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _emoji,
                    style: TextStyle(fontSize: size * 0.38),
                  ),
                  Text(
                    widget.rank.name.toUpperCase().substring(0, 1),
                    style: GoogleFonts.oswald(
                      fontSize: size * 0.18,
                      color: _primaryColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String get _rankLabel {
    switch (widget.rank) {
      case ManagerRank.bronze:
        return '青銅';
      case ManagerRank.silver:
        return '白銀';
      case ManagerRank.gold:
        return '黃金';
      case ManagerRank.platinum:
        return '白金';
      case ManagerRank.diamond:
        return '鑽石';
      case ManagerRank.legendary:
        return '傳奇';
    }
  }
}
