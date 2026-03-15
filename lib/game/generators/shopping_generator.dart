import 'dart:math';
import '../question_result.dart';

class ShoppingGenerator {
  static const _items = [
    ('🍬 アメ', 10), ('🍪 クッキー', 30), ('🍫 チョコ', 50),
    ('📏 えんぴつ', 60), ('📓 ノート', 80), ('🧃 ジュース', 120),
    ('🍞 パン', 150), ('🖊️ ペン', 200),
  ];

  static QuestionResult generate({required Random r}) {
    final a = _items[r.nextInt(_items.length)];
    final b = _items[r.nextInt(_items.length)];
    final shopIsChange = r.nextBool();
    final shopPrice    = a.$2 + b.$2;

    int shopPaid, shopChange, target;
    if (shopIsChange) {
      const units = [100, 200, 300, 500, 1000];
      shopPaid   = units.firstWhere((u) => u > shopPrice, orElse: () => 1000);
      shopChange = shopPaid - shopPrice;
      target     = shopChange;
    } else {
      shopPaid   = shopPrice;
      shopChange = 0;
      target     = shopPrice;
    }

    final s = <int>{target};
    int att = 0;
    while (s.length < 4 && att < 200) {
      att++;
      final d = target + (r.nextInt(11) - 5) * 10;
      if (d > 0 && d != target) s.add(d);
    }
    for (int i = 10; s.length < 4; i += 10) {
      if (!s.contains(target + i)) s.add(target + i);
    }

    return QuestionResult(
      target: target,
      choices: s.toList()..shuffle(r),
      shopPriceA: a.$2,
      shopPriceB: b.$2,
      shopPaid: shopPaid,
      shopChange: shopChange,
      shopIsChange: shopIsChange,
      shopItemA: a.$1,
      shopItemB: b.$1,
    );
  }
}
