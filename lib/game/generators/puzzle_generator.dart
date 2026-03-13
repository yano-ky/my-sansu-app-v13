import 'dart:math';
import '../question_result.dart';

const int kMaxMultiNum = 9;
const int kMaxDivNum   = 9;

class PuzzleGenerator {
  static QuestionResult generate({
    required int maxNum,
    required int pLv,
    required Random r,
  }) {
    int n1 = 0, n2 = 0, target = 0;
    String op = '＋';

    if (pLv == 4) {
      final type = r.nextInt(4);
      if (type == 0) {
        op = '＋'; n1 = r.nextInt(20) + 1; n2 = r.nextInt(20) + 1; target = n1 + n2;
      } else if (type == 1) {
        op = '－'; n1 = r.nextInt(20) + 10; n2 = r.nextInt(n1 - 1) + 1; target = n1 - n2;
      } else if (type == 2) {
        op = '×'; n1 = r.nextInt(kMaxMultiNum) + 1; n2 = r.nextInt(kMaxMultiNum) + 1; target = n1 * n2;
      } else {
        op = '÷'; target = r.nextInt(kMaxDivNum) + 1; n2 = r.nextInt(kMaxDivNum) + 1; n1 = target * n2;
      }
    } else {
      op = pLv == 2 ? '－' : '＋';
      target = pLv == 3 ? r.nextInt(15) + 5 : r.nextInt(15) + 2;
    }

    final s = <int>{target};
    while (s.length < 4) {
      final d = target + r.nextInt(10) - 5;
      if (d >= 1 && d != target) s.add(d);
    }

    return QuestionResult(
      n1: n1, n2: n2, target: target, op: op,
      choices: s.toList()..shuffle(r),
    );
  }
}
