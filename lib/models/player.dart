import 'dart:math' as math;
import '../data/mock_players.dart';

enum Rarity { C, B, A, S }

class PlayerCard {
  final String id;
  final String name;
  final String team;
  final String position;
  final int baseScore;
  final Rarity rarity;

  PlayerCard({
    required this.id,
    required this.name,
    required this.team,
    required this.position,
    required this.baseScore,
    required this.rarity,
  });
}

// ── 擴充方法：保持與舊版畫面渲染屬性的相容性 ──
extension PlayerCardHelpers on PlayerCard {
  double get bonusMultiplier {
    switch (rarity) {
      case Rarity.C: return 1.0;
      case Rarity.B: return 1.05;
      case Rarity.A: return 1.10;
      case Rarity.S: return 1.20;
    }
  }

  double get totalScore => baseScore * bonusMultiplier;

  String get rarityLabel => rarity.name;

  // 依據球員 ID 的 hashCode 隨機配對 dallas 目錄裡的圖片（共 13 張）
  String get imagePath {
    const images = [
      '00.png', '2.png', '7.png', '8.png', '9.png', '10.png', 
      '11.png', '13.png', '16.png', '20.png', '21.png', '25.png', '31.png'
    ];
    final index = id.hashCode.abs() % images.length;
    return 'assets/images/dallas/${images[index]}';
  }
}

// ── 抽卡邏輯更新：改讀取 mockPlayers ──
PlayerCard drawPlayer({required bool forceS}) {
  if (forceS) {
    return mockPlayers.firstWhere((p) => p.rarity == Rarity.S);
  }
  
  final rand = math.Random().nextDouble() * 100;
  Rarity pickedRarity;
  
  if (rand < 1.0) {
    pickedRarity = Rarity.S;
  } else if (rand < 7.0) {
    pickedRarity = Rarity.A;
  } else if (rand < 30.0) {
    pickedRarity = Rarity.B;
  } else {
    pickedRarity = Rarity.C;
  }

  final pool = mockPlayers.where((p) => p.rarity == pickedRarity).toList();
  if (pool.isEmpty) return mockPlayers.last;
  pool.shuffle();
  return pool.first;
}

List<PlayerCard> drawTen() {
  final results = <PlayerCard>[];
  bool hasHighRarity = false;
  
  for (int i = 0; i < 10; i++) {
    final p = drawPlayer(forceS: false);
    if (p.rarity != Rarity.C) hasHighRarity = true;
    results.add(p);
  }
  
  // 保底 B 級以上一張
  if (!hasHighRarity) {
    final bPool = mockPlayers.where((p) => p.rarity == Rarity.B).toList();
    bPool.shuffle();
    results[results.length - 1] = bPool.isNotEmpty ? bPool.first : mockPlayers.first;
  }
  
  return results;
}
