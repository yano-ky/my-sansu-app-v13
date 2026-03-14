import 'dart:math';
import '../../models/math_mode.dart';
import '../question_result.dart';

class WrongGenerator {
  static QuestionResult generate({
    required List<dynamic> wrongList,
    required Random r,
  }) {
    if (wrongList.isEmpty) return const QuestionResult();

    final q    = wrongList[0];
    final mode = MathMode.fromString(q['m'] as String);
    final n1   = (q['n1'] as int?) ?? 0;
    final n2   = (q['n2'] as int?) ?? 0;
    final t    = (q['t']  as int?) ?? 0;

    // おかいもの
    if (mode == MathMode.shopping) {
      final priceA    = (q['priceA']    as int?)    ?? t;
      final priceB    = (q['priceB']    as int?)    ?? 0;
      final itemA     = (q['itemA']     as String?) ?? '🛒 しょうひん A';
      final itemB     = (q['itemB']     as String?) ?? '🛒 しょうひん B';
      final isChange  = (q['isChange']  as int?)    == 1;
      final paid      = (q['paid']      as int?)    ?? priceA + priceB + 100;
      final target    = isChange ? paid - (priceA + priceB) : priceA + priceB;

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
        shopPriceA: priceA, shopPriceB: priceB,
        shopPaid: paid, shopChange: paid - (priceA + priceB),
        shopIsChange: isChange, shopItemA: itemA, shopItemB: itemB,
      );
    }

    // 時計
    if (mode == MathMode.clock) {
      final hour   = (q['clockHour']   as int?) ?? 12;
      final minute = (q['clockMinute'] as int?) ?? 0;
      String fun(int m) {
        if (m == 0) return '';
        const pun = {1, 3, 4, 6, 8};
        return pun.contains(m % 10) || (m ~/ 10 == 1 && m % 10 == 0) ? 'ぷん' : 'ふん';
      }
      String ts(int h, int m) => m == 0 ? '$h じ ちょうど' : '$h じ $m ${fun(m)}';
      final answer = ts(hour, minute);
      final s = <String>{answer};
      for (int h = 1; h <= 12 && s.length < 4; h++) {
        final c = ts(h, minute);
        if (c != answer) s.add(c);
      }
      for (final m in [0, 15, 30, 45]) {
        if (s.length >= 4) break;
        final c = ts(hour, m);
        if (c != answer) s.add(c);
      }
      return QuestionResult(
        target: 0,
        clockHour: hour, clockMinute: minute,
        clockQuestion: 'とけいは なんじ なんぷん？',
        clockChoices: s.toList()..shuffle(r),
        clockAnswer: answer,
      );
    }

    // 図形
    if (mode == MathMode.shape) {
      final shapeName = (q['shapeName'] as String?) ?? 'triangle';
      final question  = (q['shapeQuestion'] as String?) ?? 'この ずけいは なに？';
      final answer    = (q['shapeAnswer']   as String?) ?? 'さんかくけい';
      const allNames  = ['さんかくけい','しかくけい','ちょうほうけい','まる（えん）','ごかくけい','ろっかくけい'];
      final pool = allNames.where((n) => n != answer).toList()..shuffle(r);
      final choices = [answer, ...pool.take(3)]..shuffle(r);
      return QuestionResult(
        target: 0,
        shapeName: shapeName,
        shapeQuestion: question,
        shapeChoices: choices,
        shapeAnswer: answer,
      );
    }

    // 数の大小比較
    if (mode == MathMode.compare) {
      final correctSign = n1 > n2 ? '＞' : '＜';
      return QuestionResult(
        n1: n1, n2: n2, cmpA: n1, cmpB: n2,
        correctSign: correctSign,
        cmpChoices: ['＞', '＜']..shuffle(r),
      );
    }

    // 虫食い算
    if (mode == MathMode.fillBoth) {
      String fillOp = '＋';
      if (q['op'] != null) {
        fillOp = q['op'] as String;
      } else {
        if (n1 + n2 == t)      fillOp = '＋';
        else if (n1 - n2 == t) fillOp = '－';
        else if (n1 * n2 == t) fillOp = '×';
        else                   fillOp = '÷';
      }
      final fillIsLeft = (q['isLeft'] as int?) != 0;
      final s = <int>{t};
      int att = 0;
      while (s.length < 4 && att < 100) {
        att++;
        final d = t + r.nextInt(10) - 4;
        if (d >= 1 && d != t) s.add(d);
      }
      for (int i = 1; s.length < 4; i++) {
        if (!s.contains(t + i)) s.add(t + i);
        else if (t - i >= 1 && !s.contains(t - i)) s.add(t - i);
      }
      return QuestionResult(
        n1: n1, n2: n2, target: t,
        fillOp: fillOp, fillA: n1, fillB: n2, fillAns: t,
        fillIsLeft: fillIsLeft,
        fillChoices: s.toList()..shuffle(r),
      );
    }

    // 通常問題
    String op = '＋';
    if (mode.isMinus) op = '－';
    else if (mode.isMulti) op = '×';
    else if (mode.isDiv)   op = '÷';

    final s = <int>{t};
    while (s.length < 4) {
      final d = t + r.nextInt(10) - 5;
      if (d >= 1 && d != t) s.add(d);
    }
    return QuestionResult(
      n1: n1, n2: n2, target: t, op: op,
      choices: s.toList()..shuffle(r),
    );
  }
}
