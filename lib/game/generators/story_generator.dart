import 'dart:math';
import '../../models/math_mode.dart';
import '../question_result.dart';

const int kMaxMultiNum = 9;
const int kMaxDivNum   = 9;

class StoryGenerator {
  static const _names = [
    'たろうくん', 'はなこちゃん', 'うさぎさん',
    'おとうさん', 'おかあさん', 'くまさん', 'パンダくん',
  ];
  static const _items = {
    'アメ': '🍬', 'どんぐり': '🌰', 'シール': '⭐',
    'いちご': '🍓', 'クッキー': '🍪', 'チョコ': '🍫',
  };

  static QuestionResult generate({
    required MathMode mode,
    required int maxNum,
    required Random r,
  }) {
    final itemName = _items.keys.toList()[r.nextInt(_items.length)];
    final emoji    = _items[itemName]!;
    final name     = _names[r.nextInt(_names.length)];

    int n1, n2, target;
    String op, story;

    if (mode == MathMode.storyPlus) {
      n1 = r.nextInt(maxNum) + 1;
      n2 = r.nextInt(maxNum) + 1;
      target = n1 + n2;
      op = '＋';
      story = '$name は $itemName を $n1 こ もっていました。\nあとから $n2 こ もらうと、ぜんぶで なんこ？';
    } else if (mode == MathMode.storyMinus) {
      n1 = r.nextInt(maxNum) + 5;
      n2 = r.nextInt(n1 - 1) + 1;
      target = n1 - n2;
      op = '－';
      story = '$name は $itemName を $n1 こ もっていました。\n$n2 こ おともだちに あげると、のこりは なんこ？';
    } else if (mode == MathMode.storyMulti) {
      n1 = r.nextInt(kMaxMultiNum) + 1;
      n2 = r.nextInt(kMaxMultiNum) + 1;
      target = n1 * n2;
      op = '×';
      story = 'さらが $n1 まい あります。\n1まいの さらに $itemName を $n2 こずつ いれると、ぜんぶで なんこ？';
    } else {
      // storyDiv
      target = r.nextInt(kMaxDivNum) + 1;
      n2     = r.nextInt(kMaxDivNum) + 1;
      n1     = target * n2;
      op = '÷';
      story = '$n1 こ の $itemName を、$n2 にんで おなじかずずつ わけると、ひとり なんこ？';
    }

    final s = <int>{target};
    while (s.length < 4) {
      final d = target + r.nextInt(10) - 5;
      if (d >= 1 && d != target) s.add(d);
    }

    return QuestionResult(
      n1: n1, n2: n2, target: target, op: op,
      story: story, emoji: emoji,
      choices: s.toList()..shuffle(r),
    );
  }
}
