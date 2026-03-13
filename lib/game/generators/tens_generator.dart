import 'dart:math';
import '../question_result.dart';

class TensGenerator {
  static QuestionResult generate({required Random r}) {
    final tensBlocks   = r.nextInt(9) + 1;
    final tensOnes     = r.nextInt(10);
    final tensAskTotal = r.nextBool();
    final target       = tensAskTotal ? tensBlocks * 10 + tensOnes : tensBlocks;

    final s = <int>{target};
    int att = 0;
    while (s.length < 4 && att < 200) {
      att++;
      final d = target + r.nextInt(9) - 4;
      if (d >= 1 && d != target) s.add(d);
    }
    for (int i = 1; s.length < 4; i++) {
      if (!s.contains(target + i)) s.add(target + i);
      else if (target - i >= 1 && !s.contains(target - i)) s.add(target - i);
    }

    return QuestionResult(
      target: target,
      tensBlocks: tensBlocks,
      tensOnes: tensOnes,
      tensAskTotal: tensAskTotal,
      tensChoices: s.toList()..shuffle(r),
    );
  }
}
