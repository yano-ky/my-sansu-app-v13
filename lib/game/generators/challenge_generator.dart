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
    final item    = challengeList[idx];
    final answer  = item['answer']  as int;
    final question = item['question'] as String? ?? '';
    final from    = item['from']    as String? ?? '';
    final message = item['message'] as String? ?? '';

    // 選択肢生成（無限ループ対策つき）
    final s = <int>{answer};
    int att = 0;
    while (s.length < 4 && att < 200) {
      att++;
      final d = answer + r.nextInt(10) - 4;
      if (d >= 0 && d != answer) s.add(d);
    }
    for (int i = 1; s.length < 4; i++) {
      if (!s.contains(answer + i)) s.add(answer + i);
    }

    return QuestionResult(
      target: answer,
      choices: s.toList()..shuffle(r),
      challengeQuestion: question,
      challengeFrom:     from,
      challengeMessage:  message,
    );
  }
}
