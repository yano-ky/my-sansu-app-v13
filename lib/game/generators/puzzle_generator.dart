import 'dart:math';
import '../question_result.dart';

class PuzzleGenerator {
  static QuestionResult generate({
    required int maxNum,
    required int pLv,
    required Random r,
  }) {
    int n1 = 0, n2 = 0, target = 0;
    String op = '＋';

    switch (pLv) {
      case 1: // たしざん
        n1 = r.nextInt(maxNum) + 1;
        n2 = r.nextInt(maxNum) + 1;
        target = n1 + n2;
        op = '＋';
      case 2: // ひきざん
        n1 = r.nextInt(maxNum) + 5;
        n2 = r.nextInt(n1 - 1) + 1;
        target = n1 - n2;
        op = '－';
      case 3: // 3つのたしざん
        n1 = r.nextInt(maxNum) + 1;
        n2 = r.nextInt(maxNum) + 1;
        final n3 = r.nextInt(maxNum) + 1;
        target = n1 + n2 + n3;
        op = '＋';
        final s3 = <int>{target};
        int att3 = 0;
        while (s3.length < 4 && att3 < 100) {
          att3++;
          final d = target + r.nextInt(10) - 5;
          if (d >= 1 && d != target) s3.add(d);
        }
        for (int i = 1; s3.length < 4; i++) {
          if (!s3.contains(target + i)) s3.add(target + i);
        }
        return QuestionResult(
          n1: n1, n2: n3, target: target, op: op,
          story: '$n1 ＋ $n2 ＋ $n3 ＝ ？',
          choices: s3.toList()..shuffle(r),
        );
      default: // ぜんぶまざった (pLv == 4)
        final ops = ['＋', '－', '×', '÷'];
        op = ops[r.nextInt(ops.length)];
        switch (op) {
          case '＋':
            n1 = r.nextInt(maxNum) + 1;
            n2 = r.nextInt(maxNum) + 1;
            target = n1 + n2;
          case '－':
            n1 = r.nextInt(maxNum) + 5;
            n2 = r.nextInt(n1 - 1) + 1;
            target = n1 - n2;
          case '×':
            n1 = r.nextInt(9) + 1;
            n2 = r.nextInt(9) + 1;
            target = n1 * n2;
          default: // ÷
            target = r.nextInt(9) + 1;
            n2 = r.nextInt(9) + 1;
            n1 = target * n2;
        }
    }

    final s = <int>{target};
    int att = 0;
    while (s.length < 4 && att < 100) {
      att++;
      final d = target + r.nextInt(10) - 5;
      if (d >= 1 && d != target) s.add(d);
    }
    for (int i = 1; s.length < 4; i++) {
      if (!s.contains(target + i)) s.add(target + i);
    }

    return QuestionResult(
      n1: n1, n2: n2, target: target, op: op,
      choices: s.toList()..shuffle(r),
    );
  }
}
