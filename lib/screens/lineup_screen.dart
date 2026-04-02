import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';
import '../widgets/player_card.dart';
import '../data/mock_players.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LineupScreen extends StatefulWidget {
  final bool showBackButton;
  const LineupScreen({super.key, this.showBackButton = false});

  @override
  State<LineupScreen> createState() => _LineupScreenState();
}

class _LineupScreenState extends State<LineupScreen> {
  final Map<String, PlayerCard?> _lineup = {
    'C': null,
    'PF': null,
    'SF': null,
    'SG': null,
    'PG': null,
  };

  bool _isEditing = false;
  late List<PlayerCard> _availablePlayers;

  @override
  void initState() {
    super.initState();
    // 複製 mockPlayers 的所有球員供選擇
    _availablePlayers = List<PlayerCard>.from(mockPlayers);
    _loadLineup();
  }

  Future<void> _saveLineup() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in _lineup.entries) {
      if (entry.value != null) {
        await prefs.setString('lineup_${entry.key}', entry.value!.id);
      } else {
        await prefs.remove('lineup_${entry.key}');
      }
    }
  }

  Future<void> _loadLineup() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (final pos in _lineup.keys) {
        final id = prefs.getString('lineup_$pos');
        if (id != null) {
          try {
            _lineup[pos] = _availablePlayers.firstWhere((p) => p.id == id);
          } catch (_) {
            _lineup[pos] = null;
          }
        }
      }
    });
  }

  int get _teamPower {
    double total = 0;
    for (final p in _lineup.values) {
      if (p != null) total += p.baseScore;
    }
    return total.round();
  }

  int get _salaryUsed {
    double total = 0;
    for (final p in _lineup.values) {
      if (p != null) total += (p.baseScore * 1200000); // 簡易薪資換算
    }
    return (total / 1000000).round(); // 單位：百萬M
  }

  Future<void> _autoAssign() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.primary, width: 0.5),
        ),
        title: Text(
          '自動配置',
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '將會依最佳戰力重新排列球員',
              style: GoogleFonts.roboto(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '目前陣容將被覆蓋',
              style: GoogleFonts.roboto(color: Colors.redAccent, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '取消',
              style: GoogleFonts.roboto(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '確認',
              style: GoogleFonts.roboto(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 1. 先清空 (視覺回饋)
    setState(() {
      for (final pos in _lineup.keys) {
        _lineup[pos] = null;
      }
    });

    await Future.delayed(const Duration(milliseconds: 400));

    final sorted = List<PlayerCard>.from(_availablePlayers)
      ..sort((a, b) => b.baseScore.compareTo(a.baseScore));

    // 按照位置挑選最強，並依序填入 (AI 感覺)
    final List<String> positions = ['C', 'PF', 'SF', 'SG', 'PG'];
    final Set<PlayerCard> assigned = {};

    for (final pos in positions) {
      final match = sorted.where(
        (p) => p.position == pos && !assigned.contains(p),
      );

      if (match.isNotEmpty) {
        final best = match.first;
        assigned.add(best);
        setState(() {
          _lineup[pos] = best;
        });
        await Future.delayed(const Duration(milliseconds: 250));
      } else {
        // 如果該位置沒人，從剩餘最強補上
        final fallback = sorted.firstWhere((p) => !assigned.contains(p));
        assigned.add(fallback);
        setState(() {
          _lineup[pos] = fallback;
        });
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }

    await _saveLineup();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '陣容自動配置完成！已儲存',
            style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resetLineup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.redAccent, width: 0.5),
        ),
        title: Text(
          '重置',
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '重置會清除目前的陣容設定，確定要全部清除嗎？',
          style: GoogleFonts.roboto(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '取消',
              style: GoogleFonts.roboto(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '確定',
              style: GoogleFonts.roboto(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (final pos in _lineup.keys) {
        _lineup[pos] = null;
        prefs.remove('lineup_$pos');
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('陣容已全部清除')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A10),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: Edit/Cancel and Save
            _buildTopHeader(),
            // 70% 球場區域
            Expanded(flex: 65, child: _buildCourtArea()),
            // 30% 卡牌管理區域 (控制面板 + 滾動列表)
            Expanded(flex: 35, child: _buildControlAndListArea()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左上角
          if (_isEditing)
            const SizedBox(width: 40)
          else if (widget.showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          else
            const SizedBox(width: 40),

          // 中間標題
          Text(
            '陣容管理',
            style: GoogleFonts.oswald(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),

          // 右上角
          if (_isEditing)
            Container(
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: () {
                  _saveLineup();
                  setState(() => _isEditing = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '儲存陣容',
                  style: GoogleFonts.roboto(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildCourtArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          alignment: Alignment.center,
          children: [
            // 1. 滿版實體球場與背景板 (由 _CourtPainter 繪製)
            CustomPaint(size: Size(w, h), painter: _CourtPainter()),
            // ⚪ 2. 黑色半透明遮罩 (顏色調淡)
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.7)),
            ),
            // 3. 卡槽 Node
            _buildSlot(type: 'C', left: w / 2 - 40, top: h * 0.12),
            _buildSlot(type: 'SF', left: w * 0.82 - 65, top: h * 0.3),
            _buildSlot(type: 'SG', left: w * 0.18 - 15, top: h * 0.55),
            _buildSlot(type: 'PF', left: w * 0.18 - 15, top: h * 0.3),
            _buildSlot(type: 'PG', left: w / 2 - 40, top: h * 0.72),
          ],
        );
      },
    );
  }

  Widget _buildSlot({
    required String type,
    required double left,
    required double top,
  }) {
    final player = _lineup[type];
    return Positioned(
      left: left,
      top: top,
      child: DragTarget<PlayerCard>(
        onWillAccept: (data) => data != null,
        onAccept: (data) {
          setState(() {
            // 如果原本有人，可以在這裡做釋放
            _lineup[type] = data as PlayerCard?;
          });
        },
        builder: (context, candidateData, rejectedData) {
          final isOver = candidateData.isNotEmpty;
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 102,
                decoration: BoxDecoration(
                  color: isOver
                      ? AppColors.primary.withOpacity(0.15)
                      : Colors.black.withOpacity(0.4),
                  border: Border.all(
                    color: isOver
                        ? AppColors.primary
                        : Colors.white.withOpacity(0.12),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: player != null
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ],
                ),
                child: player != null
                    ? TweenAnimationBuilder<double>(
                        key: ValueKey(player.id),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 0.6 + 0.4 * value,
                              child: child,
                            ),
                          );
                        },
                        child: PlayerCardWidget(player: player, width: 80),
                      )
                    : Center(
                        child: Text(
                          type,
                          style: GoogleFonts.oswald(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ),
              ),
              if (player != null && _isEditing) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => setState(() => _lineup[type] = null),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildControlAndListArea() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151520),
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Column(
        children: [
          // 上半部 戰力與按鈕
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      '總戰力 (Power)',
                      _teamPower.toString(),
                      AppColors.primary,
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isEditing = !_isEditing),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isEditing ? Colors.redAccent.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isEditing ? Colors.redAccent.withOpacity(0.5) : Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isEditing ? Icons.close : Icons.edit,
                              color: _isEditing ? Colors.redAccent : Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isEditing ? '取消編輯' : '編輯陣容',
                              style: GoogleFonts.roboto(
                                color: _isEditing ? Colors.redAccent : Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildStatItem(
                      '薪資耗能 (Salary)',
                      '$_salaryUsed/120M',
                      Colors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_isEditing) ...[
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: AppColors.divider),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: _resetLineup,
                            child: Text(
                              '重置',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: _autoAssign,
                          child: Text(
                            '自動配置',
                            style: GoogleFonts.roboto(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.black26),
          // 底部 卡牌背包滾動列表
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: Colors.black38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _availablePlayers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final p = _availablePlayers[index];
                  final isInLineup = _lineup.values.contains(p);

                  return LongPressDraggable<PlayerCard>(
                    maxSimultaneousDrags: _isEditing ? 1 : 0,
                    delay: const Duration(milliseconds: 180),
                    dragAnchorStrategy: pointerDragAnchorStrategy,
                    data: p,
                    childWhenDragging: Opacity(
                      opacity: 0.4,
                      child: PlayerCardWidget(player: p, width: 80),
                    ),
                    feedback: Material(
                      color: Colors.transparent,
                      child: Transform.scale(
                        scale: 1.08,
                        child: Opacity(
                          opacity: 0.9,
                          child: PlayerCardWidget(player: p, width: 80),
                        ),
                      ),
                    ),
                    child: Opacity(
                      opacity: isInLineup ? 0.3 : 1.0,
                      child: PlayerCardWidget(player: p, width: 80),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 11, color: AppColors.textHint),
        ),
        Text(
          value,
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double paddingX = 14.0; // 左右紅色邊框寬度
    const double paddingY = 24.0; // 上下紅色邊框高度

    // 🔴 1. 外部紅色邊線 (邊框)
    final redPaint = Paint()..color = const Color(0xFFD2141E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), redPaint);

    // 🟢 2. 內部綠色球場 (畫布)
    final greenPaint = Paint()..color = const Color(0xFF00A854);
    final courtRect = Rect.fromLTRB(
      paddingX,
      paddingY,
      size.width - paddingX,
      size.height - paddingY,
    );
    canvas.drawRect(courtRect, greenPaint);

    // ⚪ 3. 白色線條
    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // 球場外框
    canvas.drawRect(courtRect, linePaint);

    // 中心半場線 (橫線)
    final centerY = courtRect.top + courtRect.height / 2;
    canvas.drawLine(
      Offset(courtRect.left, centerY),
      Offset(courtRect.right, centerY),
      linePaint,
    );

    // 中心跳球圈
    final arcCenter = Offset(size.width / 2, centerY);
    canvas.drawCircle(arcCenter, 40, linePaint);
    canvas.drawCircle(arcCenter, 12, linePaint); // 小圈

    // --- 🔱 上半場籃框線 ---
    final topBasketY = courtRect.top;

    // 3分線 (畫弧, 圓心在頂部對應 Basket 座標)
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width / 2, topBasketY),
        width: courtRect.width * 0.85,
        height: courtRect.height * 0.35,
      ),
      0,
      3.14159,
      false,
      linePaint,
    );

    // 禁區框
    final topKey = Rect.fromCenter(
      center: Offset(size.width / 2, topBasketY + courtRect.height * 0.1),
      width: courtRect.width * 0.38,
      height: courtRect.height * 0.2,
    );
    canvas.drawRect(topKey, linePaint);

    // --- 🔱 下半場籃框線 ---
    final botBasketY = courtRect.bottom;

    // 3分線
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width / 2, botBasketY),
        width: courtRect.width * 0.85,
        height: courtRect.height * 0.35,
      ),
      3.14159,
      3.14159,
      false,
      linePaint,
    );

    // 禁區框
    final botKey = Rect.fromCenter(
      center: Offset(size.width / 2, botBasketY - courtRect.height * 0.1),
      width: courtRect.width * 0.38,
      height: courtRect.height * 0.2,
    );
    canvas.drawRect(botKey, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
