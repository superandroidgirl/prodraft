import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/player.dart';
import '../data/mock_players.dart';
import '../theme/app_theme.dart';
import '../widgets/player_card.dart';

class BossScreen extends StatefulWidget {
  const BossScreen({super.key});

  @override
  State<BossScreen> createState() => _BossScreenState();
}

class _BossScreenState extends State<BossScreen>
    with TickerProviderStateMixin {
  late AnimationController _lavaController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    // 熔岩背景動畫 (緩慢循環)
    _lavaController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // 發光按鈕動畫 (呼吸燈)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _lavaController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bossPlayers = mockPlayers.where((p) => p.rarity == Rarity.S).take(5).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF070101), // 極深暗紅黑
      body: Stack(
        children: [
          // ── 1. Lava 微醺背景：自定義畫筆 ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _lavaController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _LavaPainter(progress: _lavaController.value),
                );
              },
            ),
          ),
          // 增加一層暗色霧化確保文字清晰
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      children: [
                        // ── 2. 頂部大圓角卡片 (Boss Profile) ──
                        _buildBossProfileCard(),
                        const SizedBox(height: 24),

                        // ── 3. 對戰預測 (VS Stats) ──
                        _buildVsStatsPanel(),
                        const SizedBox(height: 24),

                        // ── 4. 獎勵欄 (Reward Bar) ──
                        _buildRewardsPanel(),
                        const SizedBox(height: 24),

                        // ── 5. Boss 陣容預覽 ──
                        _buildBossLineupPanel(bossPlayers),
                        const SizedBox(height: 40),

                        // ── 6. 燃燒挑戰按鈕 ──
                        _buildBattleButton(context),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'BOSS 挑戰',
            style: GoogleFonts.oswald(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 48), // 保持標題置中
        ],
      ),
    );
  }

  Widget _buildBossProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF311B92), // 深紫
            Color(0xFFB71C1C), // 暗紅
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB71C1C).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '傳奇公牛：90年代王朝',
                  style: GoogleFonts.oswald(
                    fontSize: 16,
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '挑戰者，你認為你的隊伍能在這個歷史經典陣容下存活多久？',
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '戰力值: 99,999',
                    style: GoogleFonts.oswald(
                      fontSize: 16,
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1B0000), // 極深紅
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
              ),
              child: Text(
                '難度：極難 (Hell)',
                style: GoogleFonts.oswald(
                  fontSize: 13,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVsStatsPanel() {
    return _buildPanelContainer(
      title: '對戰預測 (VS Stats)',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVsCell(title: '你的戰力', score: '85,000', color: AppColors.primary),
              Text(
                'VS',
                style: GoogleFonts.oswald(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),
              _buildVsCell(title: 'Boss 戰力', score: '99,999', color: Colors.redAccent),
            ],
          ),
          const SizedBox(height: 16),
          // 勝率進度條
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('勝率預測', style: GoogleFonts.roboto(fontSize: 13, color: Colors.white70)),
                  Text('42%', style: GoogleFonts.oswald(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.42,
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  color: Color(0xFF4CAF50), // 鮮綠色預期勝率
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVsCell({required String title, required String score, required Color color}) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.roboto(fontSize: 12, color: Colors.white60),
        ),
        const SizedBox(height: 4),
        Text(
          score,
          style: GoogleFonts.oswald(
            fontSize: 18,
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsPanel() {
    final rewardItems = [
      _buildRewardCard('S級包碎片', Icons.auto_awesome, Colors.amber),
      _buildRewardCard('鑽石 x100', Icons.diamond, Colors.cyan),
      _buildRewardCard('專屬稱號「屠魔者」', Icons.verified_user, Colors.purpleAccent),
    ];

    return _buildPanelContainer(
      title: '挑戰獎勵 (Reward Bar)',
      child: Container(
        height: 70,
        alignment: Alignment.centerLeft,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: rewardItems.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) => rewardItems[index],
        ),
      ),
    );
  }

  Widget _buildRewardCard(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBossLineupPanel(List<PlayerCard> players) {
    return _buildPanelContainer(
      title: 'BOSS 陣容',
      child: Container(
        height: 110,
        alignment: Alignment.center,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemCount: players.isEmpty ? 5 : players.length,
          itemBuilder: (context, index) {
            final p = players.isNotEmpty ? players[index] : mockPlayers.first;
            return PlayerCardWidget(player: p, width: 75);
          },
        ),
      ),
    );
  }

  Widget _buildPanelContainer({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.oswald(
              fontSize: 15,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildBattleButton(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glowValue = _glowController.value;
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC3545).withOpacity(0.4 * glowValue + 0.1),
                blurRadius: 20 * glowValue + 4,
                spreadRadius: 3 * glowValue + 1,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('挑戰系統準備中...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC3545),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              elevation: 0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '立即進入對戰',
                  style: GoogleFonts.oswald(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  '(剩餘挑戰次數：1/1)',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── 熔岩背景自定義畫筆 ──
class _LavaPainter extends CustomPainter {
  final double progress;

  _LavaPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // ── 1. 底層火光營造大氣氛 (暗調大圓) ──
    final ambientPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    final center1 = Offset(size.width * 0.4, size.height * 0.4 + 30 * math.sin(progress * math.pi));
    ambientPaint.color = const Color(0xFF721C24).withOpacity(0.4);
    canvas.drawCircle(center1, 150, ambientPaint);

    final center2 = Offset(size.width * 0.7, size.height * 0.6);
    ambientPaint.color = const Color(0xFF4A0E4E).withOpacity(0.4);
    canvas.drawCircle(center2, 160, ambientPaint);

    // ── 2. 底層重疊火焰波形 ──
    final flamePaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final offsetLevel = size.height * (0.88 - i * 0.04);
      path.moveTo(0, offsetLevel);
      
      final waveCount = 2 + i;
      for (int w = 1; w <= waveCount; w++) {
        final section = size.width / waveCount;
        final cpX = section * (w - 0.5);
        final cpY = offsetLevel - 40 * math.sin(progress * math.pi * 2 + (i * 2 + w));
        final endX = section * w;
        final endY = size.height * (0.88 - i * 0.04 + 0.02 * math.cos(progress * math.pi * 2 + w));
        path.quadraticBezierTo(cpX, cpY, endX, endY);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      flamePaint.color = i == 0 
          ? const Color(0xFFB71C1C).withOpacity(0.4) // 深紅
          : i == 1 
              ? const Color(0xFFD32F2F).withOpacity(0.3) // 红
              : const Color(0xFFFF5722).withOpacity(0.25); // 橘紅
      canvas.drawPath(path, flamePaint);
    }

    // ── 3. 上升火星粒子 (Embers) ──
    final sparkPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    const int sparkCount = 25;
    for (int i = 0; i < sparkCount; i++) {
      final startX = (i * 47) % size.width;
      final speed = 0.7 + (i % 4) * 0.2; // 粒子上升速度差異
      final currentProgress = (progress * speed + (i * 0.13)) % 1.0; 

      final y = size.height * (1.1 - currentProgress); // 由下往上浮動
      // 左右擺動幅度
      final x = startX + 25 * math.sin(currentProgress * math.pi * 3 + i);
      final radius = 1.2 + (i % 3);

      final colorProgress = currentProgress; 
      final color = Color.lerp(
        const Color(0xFFFFD54F), // 金黃火光
        const Color(0xFFB71C1C), // 漸暗至深紅
        colorProgress,
      )!.withOpacity((1.0 - colorProgress) * 0.9);

      sparkPaint.color = color;
      canvas.drawCircle(Offset(x, y), radius, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LavaPainter oldDelegate) => oldDelegate.progress != progress;
}
