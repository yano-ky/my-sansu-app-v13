import 'dart:math';
import '../question_result.dart';

class ChallengeGenerator {
  static QuestionResult generate({
    required List<Map<String, dynamic>> challengeList,
    required int idx,
    required Random r,
  }) {
    if (challengeList.isEmpty || idx >= challengeList.length) {
      return const QuestionResult();
    }
    final answer = challengeList[idx]['answer'] as int;
    final s = <int>{answer};
    int att = 0;
    while (s.length < 4 && att < 200) {
      att++;
      final d = answer + r.nextInt(10) - 4;
      if (d >= 0 && d != answer) s.add(d);
    }
    // フォールバック：選択肢が足りない場合は確実に埋める
    for (int i = 1; s.length < 4; i++) {
      if (!s.contains(answer + i)) s.add(answer + i);
    }
    return QuestionResult(
      target: answer,
      choices: s.toList()..shuffle(r),
    );
  }
}
