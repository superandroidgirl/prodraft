import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../models/manager.dart';
import '../models/player.dart';
import '../data/mock_players.dart';
import 'boss_screen.dart';
import 'reveal_screen.dart';
import 'lineup_screen.dart';
import '../widgets/grid_painter.dart';
import 'battle_simulation_screen.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final Manager manager = demoManager;
  late AnimationController _shimmerController;
  late AnimationController _glowController;
  late AnimationController _rotateController;
  late AnimationController _fireController;

  int _teamPower = 0;
  bool _isLineupEmpty = true;
  bool _isLoadingLineup = true;

  int _freePulls = 2;
  String _countdownText = "23:59:59";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _fireController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _loadLineupAndPower();
    _loadGachaStats();
  }

  Future<void> _loadGachaStats() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    final lastDate = prefs.getString('last_gacha_date') ?? "";

    if (todayStr != lastDate) {
      await prefs.setString('last_gacha_date', todayStr);
      await prefs.setInt('free_pulls_remaining', 2);
      if (mounted) setState(() => _freePulls = 2);
    } else {
      if (mounted) {
        setState(() => _freePulls = prefs.getInt('free_pulls_remaining') ?? 0);
      }
    }
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final diff = tomorrow.difference(now);

      final hours = diff.inHours.toString().padLeft(2, '0');
      final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

      if (mounted) {
        setState(() => _countdownText = "$hours:$minutes:$seconds");
      }
    });
  }

  Future<void> _loadLineupAndPower() async {
    setState(() => _isLoadingLineup = true);
    final prefs = await SharedPreferences.getInstance();
    int power = 0;
    bool empty = true;
    final positions = ['C', 'PF', 'SF', 'SG', 'PG'];

    for (final pos in positions) {
      final id = prefs.getString('lineup_$pos');
      if (id != null) {
        try {
          final player = mockPlayers.firstWhere((p) => p.id == id);
          power += player.baseScore;
          empty = false;
        } catch (_) {}
      }
    }

    if (mounted) {
      setState(() {
        _teamPower = power;
        _isLineupEmpty = empty;
        _isLoadingLineup = false;
      });
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    _fireController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D15),
      body: VisibilityDetector(
        key: const Key('home-screen-visibility'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction == 1.0) {
            _loadLineupAndPower();
            _loadGachaStats();
          }
        },
        child: Stack(
          children: [
            // Global Grid Background
            Positioned.fill(
              child: CustomPaint(
                painter: GridPainter(color: const Color(0xFF30363D)),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0D1117).withValues(alpha: 0.8),
                    const Color(0xFF0D0D15).withValues(alpha: 1.0),
                  ],
                ),
              ),
            ),
            SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildBossBanner(),
                      const SizedBox(height: 16),
                      _buildStartBattleBanner(),
                      const SizedBox(height: 16),
                      _buildSecondaryActionRow(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[800],
                border: Border.all(color: Colors.greenAccent, width: 1.5),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/user_avatar.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.person, color: Colors.white54, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  manager.name,
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Lv.${manager.level} 黃金經理',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildCurrencyChip(Icons.circle, Colors.amber, '12.5k'),
          const SizedBox(width: 8),
          _buildCurrencyChip(Icons.diamond, Colors.lightBlueAccent, '75'),
        ],
      ),
    );
  }

  Widget _buildStartBattleBanner() {
    if (_isLoadingLineup) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A25),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }

    return _isLineupEmpty ? _buildWarningState() : _buildReadyState();
  }

  Widget _buildReadyState() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xFF0D1117).withValues(alpha: 0.2),
            border: Border.all(
              color: const Color(0xFF00FF88).withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Sweep Gradient Border Effect
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _rotateController,
                  builder: (context, child) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.transparent, width: 1.5),
                    ),
                    child: CustomPaint(
                      painter: _SweepBorderPainter(
                        animation: _rotateController.value,
                        color: const Color(0xFF00FF88),
                      ),
                    ),
                  ),
                ),
              ),
              // Plasma Flow
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) => CustomPaint(
                    painter: _PlasmaFlowPainter(
                      _shimmerController.value,
                      const Color(0xFF00FF88).withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildStatusDot(const Color(0xFF00FF88)),
                        const SizedBox(width: 8),
                        Text(
                          'SYSTEM READY // 系統就緒',
                          style: GoogleFonts.shareTechMono(
                            color: const Color(0xFF00FF88),
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '[ $_teamPower ]',
                            style: GoogleFonts.orbitron(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF00FF88),
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'OVERALL POWER // 陣容總戰力',
                            style: GoogleFonts.shareTechMono(
                              fontSize: 11,
                              color: Colors.white60,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          _buildGlassButton(
                            text: 'START BATTLE / 開始對戰',
                            color: const Color(0xFF00FF88),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BattleSimulationScreen(),
                                ),
                              );
                            },
                          ),
                          /*
                          const SizedBox(height: 12),
                          _buildGlassButton(
                            text: 'TACTICAL MATCH / 戰略模式',
                            color: Colors.amberAccent,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StandardBattleScreen(),
                                ),
                              );
                            },
                          ),
                          */
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningState() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.red.withValues(alpha: 0.05),
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Critical Watermark
              Positioned.fill(
                child: Center(
                  child: Transform.rotate(
                    angle: -0.5,
                    child: Text(
                      'CRITICAL WARNING',
                      style: GoogleFonts.oswald(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.red.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildStatusDot(Colors.redAccent),
                        const SizedBox(width: 8),
                        Text(
                          'CRITICAL ERROR // 陣容缺失',
                          style: GoogleFonts.shareTechMono(
                            color: Colors.redAccent,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _rotateController,
                            builder: (context, child) => Transform(
                              alignment: Alignment.center,
                                transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.002)
                                ..rotateY(_rotateController.value * math.pi * 2),
                              child: const Icon(
                                Icons.warning_rounded,
                                color: Colors.redAccent,
                                size: 54,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '請先前往陣容配置球員',
                            style: GoogleFonts.shareTechMono(
                              fontSize: 12,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: _buildGlassButton(
                        text: 'CONFIGURE / 前往設定',
                        color: Colors.redAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LineupScreen(showBackButton: true),
                            ),
                          ).then((_) => _loadLineupAndPower());
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDot(Color color) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.5 + 0.5 * _glowController.value),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5 * _glowController.value),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
    double glowOpacity = 0.3,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: glowOpacity),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
            ),
            child: Text(
              text,
              style: GoogleFonts.shareTechMono(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyChip(IconData icon, Color color, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.oswald(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBossBanner() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF1A1A25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BossScreen()),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background Image (Full width)
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/boss_bg.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1A1A25), Color(0xFF2A1A15)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.sports_basketball,
                          color: Colors.white10,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.4),
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      stops: const [0.0, 0.4, 0.8],
                    ),
                  ),
                ),
                // Fire Animation Layer
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _fireController,
                    builder: (context, child) => CustomPaint(
                      painter: _FireFlamePainter(_fireController.value),
                    ),
                  ),
                ),
                // Content (Right side)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 24, 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: Colors.orange,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '今日 Boss 挑戰',
                              style: GoogleFonts.oswald(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.orange.withValues(alpha: 0.5),
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '目前戰力：',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '480',
                              style: GoogleFonts.oswald(
                                color: Colors.orangeAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '距離獲勝還差 10,000 Power',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '立即挑戰',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF332200),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.play_arrow,
                                color: Color(0xFF332200),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryActionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              title: '免費抽卡',
              subtitle: '剩餘次數：$_freePulls',
              countdown: '下次刷新倒數: $_countdownText',
              buttonText: _freePulls > 0 ? '領取' : '明日再戰',
              iconOverlay: 'FREE',
              icon: Icons.card_giftcard,
              themeColor: _freePulls > 0
                  ? const Color(0xFF00E5FF) // Cyan/Blue
                  : Colors.grey,
              bgColor: const Color(0xFF0A151A),
              painter: (progress, glow) =>
                  _FreePackParticlePainter(progress, glow),
              onTap: () async {
                if (_freePulls <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('今日免費次數已用罄，明日午夜重置！')),
                  );
                  return;
                }

                final prefs = await SharedPreferences.getInstance();
                setState(() => _freePulls--);
                await prefs.setInt('free_pulls_remaining', _freePulls);

                if (!mounted) return;
                final player = drawPlayer(forceS: false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RevealScreen(
                      players: [player],
                      packImagePath: 'assets/images/pack_blue.png',
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              title: '每日任務',
              subtitle: '進度：2 / 5',
              countdown: '獎勵可領取',
              buttonText: '查看',
              iconOverlay: '',
              icon: Icons.emoji_events,
              themeColor: const Color(0xFFFF9100),
              bgColor: const Color(0xFF1A120A),
              painter: (progress, glow) => _TaskSparkPainter(progress, glow),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required String countdown,
    required String buttonText,
    required String iconOverlay,
    required IconData icon,
    required Color themeColor,
    required Color bgColor,
    required CustomPainter Function(double progress, double glow) painter,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowController, _shimmerController]),
      builder: (context, child) {
        final glowValue = _glowController.value;
        final shimmerValue = _shimmerController.value;

        return Container(
          height: 240,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: themeColor.withValues(alpha: 0.3 + (0.3 * glowValue)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.15 * glowValue),
                blurRadius: 15 * glowValue,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: painter(shimmerValue, glowValue)),
                ),
                // Icon Area
                Positioned(
                  top: 24,
                  left: 24,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: themeColor.withValues(alpha: 0.1),
                          border: Border.all(
                            color: themeColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(icon, color: themeColor, size: 28),
                      ),
                      if (iconOverlay.isNotEmpty)
                        Positioned(
                          bottom: -4,
                          left: -10,
                          child: Transform.rotate(
                            angle: -0.15,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: themeColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                iconOverlay,
                                style: GoogleFonts.oswald(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Text Content
                Positioned(
                  top: 24,
                  right: 24,
                  left: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.oswald(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
                // Countdown/Small Text
                Positioned(
                  top: 110,
                  left: 16,
                  right: 16,
                  child: Text(
                    countdown,
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Button
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeColor.withValues(alpha: 0.8),
                          themeColor,
                          themeColor.withValues(alpha: 0.7),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(20),
                        child: Center(
                          child: Text(
                            buttonText,
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
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

class _PlasmaFlowPainter extends CustomPainter {
  final double progress;
  final Color baseColor;
  _PlasmaFlowPainter(this.progress, this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          baseColor.withValues(alpha: 0.0),
          baseColor.withValues(alpha: 0.05),
          baseColor.withValues(alpha: 0.0),
        ],
        stops: [
          (progress - 0.3).clamp(0.0, 1.0),
          progress,
          (progress + 0.3).clamp(0.0, 1.0),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_PlasmaFlowPainter old) => true;
}

class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _TypewriterText({required this.text, required this.style});

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _charCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _charCount = StepTween(
      begin: 0,
      end: widget.text.length,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _charCount,
      builder: (context, child) {
        String visibleText = widget.text.substring(0, _charCount.value);
        return Text(visibleText, style: widget.style);
      },
    );
  }
}

class _FreePackParticlePainter extends CustomPainter {
  final double progress;
  final double glowProgress;
  _FreePackParticlePainter(this.progress, this.glowProgress);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final random = math.Random(42);
    final baseColor = const Color(0xFF00FF88);

    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final y =
          (random.nextDouble() * size.height + progress * 50) % size.height;
      final radius = random.nextDouble() * 2 + 0.5;

      final individualOpacity =
          0.3 + 0.7 * math.sin(progress * math.pi * 2 + i);
      final paint = Paint()
        ..color = baseColor.withValues(alpha: 
          (0.3 * individualOpacity * glowProgress).clamp(0.0, 1.0),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_FreePackParticlePainter old) => true;
}

class _TaskSparkPainter extends CustomPainter {
  final double progress;
  final double glowProgress;
  _TaskSparkPainter(this.progress, this.glowProgress);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final random = math.Random(123);
    final baseColor = const Color(0xFFFF9100);

    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y =
          (random.nextDouble() * size.height - progress * 80 + size.height) %
          size.height;
      final width = random.nextDouble() * 2 + 1;
      final height = random.nextDouble() * 4 + 2;

      final individualOpacity =
          0.2 + 0.8 * math.sin(progress * math.pi * 3 + i);
      final paint = Paint()
        ..color = baseColor.withValues(alpha: 
          (0.2 * individualOpacity * glowProgress).clamp(0.0, 1.0),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawRect(Rect.fromLTWH(x, y, width, height), paint);
    }
  }

  @override
  bool shouldRepaint(_TaskSparkPainter old) => true;
}



class _FireFlamePainter extends CustomPainter {
  final double progress;

  _FireFlamePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // Three layers of flames for depth
    // Layer 1: Dark Red / Small / Slow
    _drawFireLayer(canvas, size, 
      color: const Color(0xFFFF3300).withValues(alpha: 0.3), 
      speedScale: 0.6, 
      waveScale: 1.0, 
      radiusScale: 0.8, // Reduced from 1.5
      count: 10);

    // Layer 2: Bright Orange / Tiny / Medium speed
    _drawFireLayer(canvas, size, 
      color: const Color(0xFFFF9900).withValues(alpha: 0.4), 
      speedScale: 1.0, 
      waveScale: 0.8, 
      radiusScale: 0.6, // Reduced from 1.0
      count: 12);

    // Layer 3: Yellow Core / Atomic / Fast
    _drawFireLayer(canvas, size, 
      color: const Color(0xFFFFDD00).withValues(alpha: 0.5), 
      speedScale: 1.5, 
      waveScale: 0.6, 
      radiusScale: 0.4, // Reduced from 0.6
      count: 8);
      
    // 底部餘火 Glow (Slightly shorter)
    final glowRect = Rect.fromLTWH(0, size.height - 10, size.width, 15);
    canvas.drawRect(
      glowRect, 
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.deepOrange.withValues(alpha: 0.2 + 0.1 * math.sin(progress * math.pi * 4))
          ],
        ).createShader(glowRect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15)
    );
  }

  void _drawFireLayer(Canvas canvas, Size size, {
    required Color color, 
    required double speedScale, 
    required double waveScale, 
    required double radiusScale,
    required int count
  }) {
    for (int i = 0; i < count; i++) {
      final r = math.Random(i * 101);
      final startX = r.nextDouble() * size.width;
      
      // Shorter distance: Use 0.7 instead of 1.2
      final t = (progress * speedScale + (i / count)) % 1.0;
      final y = size.height * (1.05 - t * 0.6); // Rising range reduced
      
      // Horizontal wave (flicker)
      final xDrift = math.sin((progress * 4 * math.pi) + (i * 2)) * 10 * waveScale;
      final x = (startX + xDrift) % size.width;

      // Pulse size
      final pulse = 0.8 + 0.2 * math.cos(progress * 6 * math.pi + i);
      // Base size reduced from 20+20 to 12+12
      final radius = (12.0 + r.nextDouble() * 12.0) * radiusScale * pulse * (1.0 - t * 0.5);

      final paint = Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.5);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FireFlamePainter oldDelegate) => true;
}

class _SweepBorderPainter extends CustomPainter {
  final double animation;
  final Color color;

  _SweepBorderPainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));
    
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0),
          color,
          color.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(animation * 2 * math.pi),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _SweepBorderPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
