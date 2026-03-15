import 'dart:math';
import '../question_result.dart';

class ClockGenerator {
  // 時計問題で使う分の読み方（5分刻み）
  static String _fun(int m) {
    const map = {
      0:  '',
      5:  '5ふん',
      10: '10ぷん',
      15: '15ふん',
      20: '20ぷん',
      25: '25ふん',
      30: '30ぷん',
      35: '35ふん',
      40: '40ぷん',
      45: '45ふん',
      50: '50ぷん',
      55: '55ふん',
    };
    return map[m] ?? '$m ふん';
  }

  static String _timeStr(int h, int m) {
    if (m == 0) return '$h じ ちょうど';
    return '$h じ ${_fun(m)}';
  }

  static QuestionResult generate({required Random r}) {
    final lv   = r.nextInt(5);
    final hour = r.nextInt(12) + 1;
    int minute = 0;
    String answer, question;

    if (lv == 0) {
      minute   = 0;
      answer   = _timeStr(hour, 0);
      question = 'とけいは なんじ？';
    } else if (lv == 1) {
      minute   = 30;
      answer   = _timeStr(hour, 30);
      question = 'とけいは なんじ なんぷん？';
    } else if (lv == 2) {
      minute   = [15, 45][r.nextInt(2)];
      answer   = _timeStr(hour, minute);
      question = 'とけいは なんじ なんぷん？';
    } else if (lv == 3) {
      final mins = [5, 10, 20, 25, 35, 40, 50, 55];
      minute   = mins[r.nextInt(mins.length)];
      answer   = _timeStr(hour, minute);
      question = 'とけいは なんじ なんぷん？';
    } else {
      minute        = [0, 30][r.nextInt(2)];
      final add     = r.nextInt(5) + 1;
      final after   = ((hour - 1 + add) % 12) + 1;
      answer   = _timeStr(after, minute);
      question = '${_timeStr(hour, minute)} から $add じかん ごは なんじ？';
      // lv4は答えの時刻をclockHourに入れる（時計表示は答えの時刻）
      return QuestionResult(
        target: 0,
        clockHour: after,
        clockMinute: minute,
        clockQuestion: question,
        clockChoices: _makeChoices(answer, after, minute),
        clockAnswer: answer,
      );
    }

    return QuestionResult(
      target: 0,
      clockHour: hour,
      clockMinute: minute,
      clockQuestion: question,
      clockChoices: _makeChoices(answer, hour, minute),
      clockAnswer: answer,
    );
  }

  static List<String> _makeChoices(String answer, int hour, int minute, [Random? r]) {
    final rand = r ?? Random();
    final s = <String>{answer};
    final candidates = <String>[];
    for (int h = 1; h <= 12; h++) {
      final c = _timeStr(h, minute);
      if (c != answer) candidates.add(c);
    }
    for (final m in [0, 15, 30, 45]) {
      final c = _timeStr(hour, m);
      if (c != answer) candidates.add(c);
    }
    candidates.shuffle(rand);
    for (final c in candidates) {
      if (s.length >= 4) break;
      s.add(c);
    }
    return s.toList()..shuffle(rand);
  }
}
