import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pack.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';

import 'reveal_screen.dart';

class GachaShopScreen extends StatefulWidget {
  const GachaShopScreen({super.key});

  @override
  State<GachaShopScreen> createState() => _GachaShopScreenState();
}

class _GachaShopScreenState extends State<GachaShopScreen> {
  int _currentPackIndex = 1; // default to silver (middle)
  final PageController _pageController = PageController(
    viewportFraction: 0.7,
    initialPage: 1,
  );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Pack get _currentPack => availablePacks[_currentPackIndex];

  Color get _currentPackColor {
    switch (_currentPack.tier) {
      case PackTier.bronze:
        return AppColors.rankBronze;
      case PackTier.silver:
        return AppColors.rankSilver;
      case PackTier.gold:
        return AppColors.secondary;
    }
  }

  void _doSinglePull() {
    final player = drawPlayer(forceS: false);
    String packImagePath = 'assets/images/pack_blue.png';
    if (_currentPack.tier == PackTier.silver) packImagePath = 'assets/images/pack_silver.png';
    if (_currentPack.tier == PackTier.gold) packImagePath = 'assets/images/pack_gold.png';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RevealScreen(
          players: [player],
          packImagePath: packImagePath,
        ),
      ),
    );
  }

  void _doTenPull() {
    final players = drawTen();
    String packImagePath = 'assets/images/pack_blue.png';
    if (_currentPack.tier == PackTier.silver) packImagePath = 'assets/images/pack_silver.png';
    if (_currentPack.tier == PackTier.gold) packImagePath = 'assets/images/pack_gold.png';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RevealScreen(
          players: players,
          packImagePath: packImagePath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              // ── Top area: text carousel + info (fixed height) ──
              _buildPackCarousel(),
              const SizedBox(height: 16),
              _buildPackInfo(),
              const SizedBox(height: 20),
              // ── Pack image showcase ──
              _buildPackShowcase(),
              const Spacer(),
              _buildPullButtons(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.goldGradient.createShader(bounds),
            child: Text(
              '招募中心',
              style: GoogleFonts.oswald(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          const Spacer(),
          _buildCurrencyDisplay(),
        ],
      ),
    );
  }

  Widget _buildCurrencyDisplay() {
    return Row(
      children: [
        _MiniCurrencyBadge(emoji: '🪙', value: '12.5k', color: AppColors.secondary),
        const SizedBox(width: 8),
        _MiniCurrencyBadge(emoji: '💎', value: '75', color: AppColors.rankDiamond),
      ],
    );
  }

  // ── Horizontal text-style pack carousel ──
  Widget _buildPackCarousel() {
    return SizedBox(
      height: 140,
      child: PageView.builder(
        controller: _pageController,
        itemCount: availablePacks.length,
        onPageChanged: (i) => setState(() => _currentPackIndex = i),
        itemBuilder: (context, index) {
          final pack = availablePacks[index];
          final isCenter = index == _currentPackIndex;
          return AnimatedScale(
            scale: isCenter ? 1.0 : 0.82,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: _PackTextCard(pack: pack, isHighlighted: isCenter),
          );
        },
      ),
    );
  }

  // ── Pack name / description / price ──
  Widget _buildPackInfo() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Padding(
        key: ValueKey(_currentPackIndex),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Text(
              _currentPack.name,
              style: GoogleFonts.oswald(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _currentPackColor,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _currentPack.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PriceChip(pack: _currentPack),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Three pack image cards side-by-side as showcase ──
  Widget _buildPackShowcase() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '卡包系列',
                style: GoogleFonts.oswald(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '點擊卡包可切換',
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(availablePacks.length, (index) {
              final pack = availablePacks[index];
              final isSelected = index == _currentPackIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _currentPackIndex = index);
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: _PackImageCard(
                    pack: pack,
                    isSelected: isSelected,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildPullButtons() {
    final currency = _currentPack.currency == PackCurrency.coins ? '🪙' : '💎';
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
              onPressed: _doTenPull,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '十連抽  $currency ${_currentPack.price * 10}',
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
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _currentPackColor.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _doSinglePull,
              child: Text(
                '單抽  $currency ${_currentPack.price}',
                style: GoogleFonts.oswald(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _currentPackColor,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// Text-based pack card for the horizontal PageView carousel
// ──────────────────────────────────────────────────────
class _PackTextCard extends StatelessWidget {
  final Pack pack;
  final bool isHighlighted;

  const _PackTextCard({required this.pack, required this.isHighlighted});

  Color get _tierColor {
    switch (pack.tier) {
      case PackTier.bronze:
        return AppColors.rankBronze;
      case PackTier.silver:
        return AppColors.rankSilver;
      case PackTier.gold:
        return AppColors.secondary;
    }
  }

  String get _tierEmoji {
    switch (pack.tier) {
      case PackTier.bronze:
        return '📦';
      case PackTier.silver:
        return '🎖️';
      case PackTier.gold:
        return '✨';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardSurface,
            _tierColor.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlighted
              ? _tierColor.withValues(alpha: 0.8)
              : _tierColor.withValues(alpha: 0.2),
          width: isHighlighted ? 2.0 : 1.0,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: _tierColor.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_tierEmoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pack.name,
                style: GoogleFonts.oswald(
                  fontSize: 18,
                  color: _tierColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'x${pack.cardCount} 張 / 次',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: AppColors.textSecondary,
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
// Image-based pack card for the lower showcase row
// ──────────────────────────────────────────────────────
class _PackImageCard extends StatelessWidget {
  final Pack pack;
  final bool isSelected;

  const _PackImageCard({required this.pack, required this.isSelected});

  String get _imagePath {
    switch (pack.tier) {
      case PackTier.bronze:
        return 'assets/images/pack_blue.png';
      case PackTier.silver:
        return 'assets/images/pack_silver.png';
      case PackTier.gold:
        return 'assets/images/pack_gold.png';
    }
  }

  Color get _tierColor {
    switch (pack.tier) {
      case PackTier.bronze:
        return AppColors.rankBronze;
      case PackTier.silver:
        return AppColors.rankSilver;
      case PackTier.gold:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: _tierColor.withValues(alpha: 0.6),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 0.68, // portrait pack shape
              child: Image.asset(
                _imagePath,
                fit: BoxFit.cover,
              ),
            ),
            // Selected indicator: glowing border overlay
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _tierColor,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            // Pack name label at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: Text(
                  pack.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.oswald(
                    fontSize: 11,
                    color: isSelected ? _tierColor : Colors.white70,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// Shared sub-widgets
// ──────────────────────────────────────────────────────

class _PriceChip extends StatelessWidget {
  final Pack pack;
  const _PriceChip({required this.pack});

  @override
  Widget build(BuildContext context) {
    final currency = pack.currency == PackCurrency.coins ? '🪙' : '💎';
    final color = pack.currency == PackCurrency.coins
        ? AppColors.secondary
        : AppColors.rankDiamond;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$currency ${pack.price} / 抽',
        style: GoogleFonts.oswald(
          fontSize: 14,
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _MiniCurrencyBadge extends StatelessWidget {
  final String emoji;
  final String value;
  final Color color;
  const _MiniCurrencyBadge({
    required this.emoji,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.oswald(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
