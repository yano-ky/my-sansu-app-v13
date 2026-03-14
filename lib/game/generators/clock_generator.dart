import 'dart:math';
import '../question_result.dart';

class ClockGenerator {
  static QuestionResult generate({required Random r}) {
    // 難易度をランダムに選ぶ
    // lv0: ちょうど〜時、lv1: 〜時30分、lv2: 〜時15/45分、lv3: 5分刻み、lv4: 時間後
    final lv = r.nextInt(5);

    final hour   = r.nextInt(12) + 1;
    int minute   = 0;
    String answer, question;
    List<String> choices;

    if (lv == 0) {
      minute   = 0;
      answer   = '$hour じ ちょうど';
      question = 'とけいは なんじ なんぷん？';
    } else if (lv == 1) {
      minute   = 30;
      answer   = '$hour じ $minute ぷん';
      question = 'とけいは なんじ なんぷん？';
    } else if (lv == 2) {
      minute   = [15, 45][r.nextInt(2)];
      answer   = '$hour じ $minute ぷん';
      question = 'とけいは なんじ なんぷん？';
    } else if (lv == 3) {
      final mins = [5,10,20,25,35,40,50,55];
      minute   = mins[r.nextInt(mins.length)];
      answer   = '$hour じ $minute ぷん';
      question = 'とけいは なんじ なんぷん？';
    } else {
      // 〜時間後は何時？
      minute      = [0, 30][r.nextInt(2)];
      final add   = r.nextInt(5) + 1;
      final after = ((hour - 1 + add) % 12) + 1;
      answer   = '$after じ${minute == 0 ? ' ちょうど' : ' $minute ぷん'}';
      question = '$hour じ${minute == 0 ? ' ちょうど' : ' $minute ぷん'} から $add じかん ご は なんじ？';
    }

    // 選択肢（正解＋ダミー3つ）
    final s = <String>{answer};
    final pool = <String>[];
    for (int h = 1; h <= 12; h++) {
      for (final m in [0, 15, 30, 45]) {
        final c = m == 0 ? '$h じ ちょうど' : '$h じ $m ぷん';
        if (c != answer) pool.add(c);
      }
    }
    pool.shuffle(r);
    for (final c in pool) {
      if (s.length >= 4) break;
      s.add(c);
    }
    choices = s.toList()..shuffle(r);

    return QuestionResult(
      target: 0,
      clockHour: hour,
      clockMinute: minute,
      clockQuestion: question,
      clockChoices: choices,
      clockAnswer: answer,
    );
  }
}
