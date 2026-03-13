import 'dart:math';
import '../question_result.dart';

const int kMaxMultiNum = 9;

class MultiGenerator {
  static QuestionResult generate({required Random r}) {
    final n1 = r.nextInt(kMaxMultiNum) + 1;
    final n2 = r.nextInt(kMaxMultiNum) + 1;
    final target = n1 * n2;
    return QuestionResult(
      n1: n1, n2: n2, target: target, op: '×',
      choices: _choices(target, r),
    );
  }

  static List<int> _choices(int target, Random r) {
    final s = <int>{target};
    while (s.length < 4) {
      final d = target + r.nextInt(10) - 5;
      if (d >= 1 && d != target) s.add(d);
    }
    return s.toList()..shuffle(r);
  }
}
