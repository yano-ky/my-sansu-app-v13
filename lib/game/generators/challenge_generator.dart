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
    while (s.length < 4) {
      final d = answer + r.nextInt(10) - 4;
      if (d >= 0) s.add(d);
    }
    return QuestionResult(
      target: answer,
      choices: s.toList()..shuffle(r),
    );
  }
}
