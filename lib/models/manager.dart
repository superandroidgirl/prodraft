enum ManagerRank {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  legendary,
}

class Manager {
  final String name;
  final ManagerRank rank;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final int rp;
  final int coins;
  final int gems;
  final bool dailyPackClaimed;

  const Manager({
    required this.name,
    required this.rank,
    required this.level,
    required this.xp,
    required this.xpToNextLevel,
    required this.rp,
    required this.coins,
    required this.gems,
    this.dailyPackClaimed = false,
  });

  String get rankLabel {
    switch (rank) {
      case ManagerRank.bronze:
        return '青銅經理';
      case ManagerRank.silver:
        return '白銀經理';
      case ManagerRank.gold:
        return '黃金經理';
      case ManagerRank.platinum:
        return '白金經理';
      case ManagerRank.diamond:
        return '鑽石經理';
      case ManagerRank.legendary:
        return '傳奇經理';
    }
  }

  double get xpProgress => xp / xpToNextLevel;
}

// Default demo manager
const demoManager = Manager(
  name: 'ProDraft MVP',
  rank: ManagerRank.gold,
  level: 12,
  xp: 3400,
  xpToNextLevel: 5000,
  rp: 1850,
  coins: 12480,
  gems: 75,
);
