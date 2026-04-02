import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/manager.dart';
import '../theme/app_theme.dart';
import 'all_cards_screen.dart';

class ManagerHubScreen extends StatefulWidget {
  const ManagerHubScreen({super.key});

  @override
  State<ManagerHubScreen> createState() => _ManagerHubScreenState();
}

class _ManagerHubScreenState extends State<ManagerHubScreen> {
  final Manager manager = demoManager;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D15),
      body: CustomScrollView(
        slivers: [
          _buildTopProfile(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildManagerCard(),
                  const SizedBox(height: 16),
                  _buildCoreStatsGrid(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('戰績綜覽', ''),
                  const SizedBox(height: 8),
                  _buildBattleOverview(),
                  const SizedBox(height: 16),
                  _buildSectionHeader('最近十場', ''),
                  const SizedBox(height: 8),
                  _buildRecentGamesChart(),
                  const SizedBox(height: 16),
                  _buildSectionHeader(
                    '收藏 & 成就',
                    '查看全部 >',
                    onActionTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllCardsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildCollectionGrid(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProfile(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.greenAccent, width: 2),
                  ),
                  child: const CircleAvatar(
                    backgroundImage: AssetImage(
                      'assets/images/user_avatar.png',
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0D0D15),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manager.name,
                    style: GoogleFonts.oswald(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Lv.12 ${manager.rankLabel}',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
            _buildHeaderBadge(Icons.monetization_on, '12.5k', Colors.amber),
            const SizedBox(width: 8),
            _buildHeaderBadge(Icons.diamond, '75', Colors.cyanAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBadge(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.oswald(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151520),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge with Glow
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.shield,
                    size: 80,
                    color: Colors.blue.withValues(alpha: 0.4),
                  ),
                  const Icon(
                    Icons.auto_awesome,
                    size: 45,
                    color: Colors.cyanAccent,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '鑽石經理人 III',
                  style: GoogleFonts.oswald(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'ID #1.0083:34',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 0.57,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF00E676),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'EXP: 860 / 1500',
                  style: GoogleFonts.oswald(
                    fontSize: 13,
                    color: Colors.white54,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreStatsGrid() {
    return GridView.count(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildCoreStatCard(
          '積分 (RP)',
          '1850',
          Icons.trending_up,
          const Color(0xFF00E676),
        ),
        _buildCoreStatCard('勝率', '62%', Icons.stars, Colors.amber),
        _buildCoreStatCard('總場次', '245', Icons.public, Colors.amber),
        _buildCoreStatCard('排名', '#1,284', Icons.bar_chart, Colors.cyanAccent),
      ],
    );
  }

  Widget _buildCoreStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151520),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.oswald(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: const Color.fromARGB(255, 255, 255, 255),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBattleOverview() {
    return Row(
      children: [
        _buildSmallStatBox('勝場', '152', Icons.flash_on, Colors.amber),
        const SizedBox(width: 12),
        _buildSmallStatBox('敗場', '93', Icons.bolt, Colors.cyanAccent),
        const SizedBox(width: 12),
        _buildSmallStatBox('週戰速', '3', Icons.emoji_events, Colors.amber),
        const SizedBox(width: 12),
        _buildSmallStatBox(
          '連勝紀錄',
          '9',
          Icons.local_fire_department,
          Colors.cyanAccent,
        ),
      ],
    );
  }

  Widget _buildSmallStatBox(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF151520),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color.withValues(alpha: 0.7)),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.oswald(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentGamesChart() {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151520),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.cyanAccent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: CustomPaint(size: Size.infinite, painter: _RecentGamesPainter()),
    );
  }

  Widget _buildCollectionGrid() {
    return GridView.count(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _buildCollectionCard(
          '已收藏球員',
          '106',
          Icons.wallet_giftcard,
          Colors.greenAccent,
        ),
        _buildCollectionCard('傳奇卡數量', '12', Icons.star, Colors.amber),
        _buildCollectionCard('稀有卡數量', '38', Icons.star_border, Colors.amber),
        _buildCollectionCard('成就完成度', '19', Icons.favorite, Colors.cyanAccent),
      ],
    );
  }

  Widget _buildCollectionCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151520),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.oswald(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.1), size: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String action, {
    VoidCallback? onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (action.isNotEmpty)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              action,
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: Colors.greenAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentGamesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / 15;
    final spacing = (size.width - (barWidth * 10)) / 9;

    final paintGreen = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.6);
    final paintRed = Paint()..color = Colors.red.withValues(alpha: 0.3);
    final paintLine = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final paintDot = Paint()..color = Colors.cyanAccent;

    final List<double> values = [
      0.8,
      0.6,
      0.7,
      0.4,
      0.5,
      0.7,
      0.8,
      0.6,
      0.9,
      0.7,
    ];
    final List<bool> wins = [
      true,
      true,
      true,
      false,
      false,
      true,
      true,
      true,
      true,
      true,
    ];

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final List<String> labels = [
      'W',
      '2',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '0',
      '7',
    ];
    final path = Path();

    for (int i = 0; i < 10; i++) {
      final x = i * (barWidth + spacing) + barWidth / 2;
      final y = size.height * (1 - values[i]);

      // Draw bars
      final barRect = Rect.fromLTWH(
        i * (barWidth + spacing),
        size.height * (1 - values[i] * 0.8) - 20,
        barWidth,
        values[i] * 0.8 * size.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(6)),
        wins[i] ? paintGreen : paintRed,
      );

      // Draw Labels
      textPainter.text = TextSpan(
        text: labels[i],
        style: GoogleFonts.roboto(
          fontSize: 10,
          color: Colors.white24,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 15),
      );

      // Path for line chart
      if (i == 0) {
        path.moveTo(x, y - 20);
      } else {
        path.lineTo(x, y - 20);
      }
    }

    canvas.drawPath(path, paintLine);

    // Draw dots
    for (int i = 0; i < 10; i++) {
      final x = i * (barWidth + spacing) + barWidth / 2;
      final y = size.height * (1 - values[i]) - 20;
      canvas.drawCircle(Offset(x, y), 4, paintDot);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
