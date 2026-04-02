import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/mock_players.dart';
import '../widgets/player_card.dart';
import 'card_detail_screen.dart';

class AllCardsScreen extends StatelessWidget {
  const AllCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '所有卡牌',
          style: GoogleFonts.oswald(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ── 背景霧化或貼圖 ──
          Positioned.fill(
            child: Image.asset(
              'assets/images/blue_mist_bg.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.4),
            ),
          ),
          
          SafeArea(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.73, // 跟卡牌比例對應
              ),
              itemCount: mockPlayers.length,
              itemBuilder: (context, index) {
                final p = mockPlayers[index];
                
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, __, ___) => CardDetailScreen(
                          player: p,
                          heroTag: 'card_all_${p.id}',
                        ),
                        transitionsBuilder: (_, animation, __, child) =>
                            FadeTransition(opacity: animation, child: child),
                        transitionDuration: const Duration(milliseconds: 400),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'card_all_${p.id}',
                    child: PlayerCardWidget(player: p, width: double.infinity),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
