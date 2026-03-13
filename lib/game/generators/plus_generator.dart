import 'dart:math';
import '../question_result.dart';

class PlusGenerator {
  static QuestionResult generate({required int maxNum, required Random r}) {
    final n1 = r.nextInt(maxNum) + 1;
    final n2 = r.nextInt(maxNum) + 1;
    final target = n1 + n2;
    return QuestionResult(
      n1: n1, n2: n2, target: target, op: '＋',
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
