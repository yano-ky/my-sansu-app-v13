import 'dart:math';
import '../question_result.dart';

class CompareGenerator {
  static QuestionResult generate({required int maxNum, required Random r}) {
    int cmpA = r.nextInt(maxNum) + 1;
    int cmpB = r.nextInt(maxNum) + 1;
    while (cmpA == cmpB) cmpB = r.nextInt(maxNum) + 1;
    final correctSign = cmpA > cmpB ? '＞' : '＜';
    final cmpChoices = ['＞', '＜']..shuffle(r);
    return QuestionResult(
      cmpA: cmpA, cmpB: cmpB,
      correctSign: correctSign,
      cmpChoices: cmpChoices,
    );
  }
}
