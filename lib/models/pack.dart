enum PackTier { bronze, silver, gold }
enum PackCurrency { coins, gems }

class Pack {
  final String id;
  final String name;
  final String description;
  final int price;
  final PackCurrency currency;
  final int cardCount;
  final PackTier tier;

  const Pack({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.cardCount,
    required this.tier,
  });
}

const List<Pack> availablePacks = [
  Pack(
    id: 'pack_bronze',
    name: '新秀卡包',
    description: '基礎卡包，適合初學者。\nC 級 85% / B 級 12% / A 級 2.5% / S 級 0.5%',
    price: 1000,
    currency: PackCurrency.coins,
    cardCount: 5,
    tier: PackTier.bronze,
  ),
  Pack(
    id: 'pack_silver',
    name: '明星卡包',
    description: '進階卡包，更高機率獲得 A 級球員。\nB 級 60% / A 級 30% / S 級 5% / 保底 1 張 A 以上',
    price: 500,
    currency: PackCurrency.gems,
    cardCount: 5,
    tier: PackTier.silver,
  ),
  Pack(
    id: 'pack_gold',
    name: '傳奇卡包',
    description: '頂級卡包 (需達 Lv.20)。\nA 級 70% / S 級 20% / 保底 1 張 S 以上',
    price: 1500,
    currency: PackCurrency.gems,
    cardCount: 10,
    tier: PackTier.gold,
  ),
];
