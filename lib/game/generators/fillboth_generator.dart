import 'dart:math';
import '../question_result.dart';

const int kMaxMultiNum = 9;
const int kMaxDivNum   = 9;

class FillBothGenerator {
  static QuestionResult generate({
    required int maxNum,
    required int fillBothLv,
    required Random r,
  }) {
    final ops = switch (fillBothLv) {
      1 => ['＋'],
      2 => ['－'],
      3 => ['×'],
      4 => ['÷'],
      _ => ['＋', '－', '×', '÷'],
    };
    final fillOp    = ops[r.nextInt(ops.length)];
    final fillIsLeft = r.nextBool();

    int fillA = 0, fillB = 0, fillAns = 0;

    switch (fillOp) {
      case '＋':
        fillA = r.nextInt(maxNum) + 1;
        fillB = r.nextInt(maxNum) + 1;
        fillAns = fillIsLeft ? fillA : fillB;
      case '－':
        fillA = r.nextInt(maxNum) + 5;
        fillB = r.nextInt(fillA - 1) + 1;
        fillAns = fillIsLeft ? fillA : fillB;
      case '×':
        fillA = r.nextInt(kMaxMultiNum) + 1;
        fillB = r.nextInt(kMaxMultiNum) + 1;
        fillAns = fillIsLeft ? fillA : fillB;
      case '÷':
        fillAns = r.nextInt(kMaxDivNum) + 1;
        fillB   = r.nextInt(kMaxDivNum) + 1;
        fillA   = fillAns * fillB;
        if (!fillIsLeft) fillAns = fillB;
    }

    // 選択肢は fillAns（正解の□の値）を基準に生成
    final s = <int>{fillAns};
    int att = 0;
    while (s.length < 4 && att < 100) {
      att++;
      final d = fillAns + r.nextInt(10) - 4;
      if (d >= 1 && d != fillAns) s.add(d);
    }
    for (int i = 1; s.length < 4; i++) {
      if (!s.contains(fillAns + i)) s.add(fillAns + i);
      else if (fillAns - i >= 1 && !s.contains(fillAns - i)) s.add(fillAns - i);
    }

    return QuestionResult(
      target: fillAns,
      fillOp: fillOp,
      fillA: fillA,
      fillB: fillB,
      fillAns: fillAns,
      fillIsLeft: fillIsLeft,
      fillChoices: s.toList()..shuffle(r),
    );
  }
}
