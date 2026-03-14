import 'dart:math';
import '../question_result.dart';

class ClockGenerator {
  // 時計問題で使う分の読み方（5分刻み）
  static String _fun(int m) {
    const map = {
      0:  '',
      5:  'ごふん',
      10: 'じゅっぷん',
      15: 'じゅうごふん',
      20: 'にじゅっぷん',
      25: 'にじゅうごふん',
      30: 'さんじゅっぷん',
      35: 'さんじゅうごふん',
      40: 'よんじゅっぷん',
      45: 'よんじゅうごふん',
      50: 'ごじゅっぷん',
      55: 'ごじゅうごふん',
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
    }

    // 正解と被らないダミー選択肢を生成
    // 近い時刻（±1〜3時間、同じ分）を優先してダミーに使う
    final s = <String>{answer};
    final candidates = <String>[];

    // 同じ分で違う時間
    for (int h = 1; h <= 12; h++) {
      final c = _timeStr(h, minute);
      if (c != answer) candidates.add(c);
    }
    // 違う分で同じ時間
    for (final m in [0, 15, 30, 45]) {
      final c = _timeStr(hour, m);
      if (c != answer) candidates.add(c);
    }
    candidates.shuffle(r);
    for (final c in candidates) {
      if (s.length >= 4) break;
      s.add(c);
    }

    return QuestionResult(
      target: 0,
      clockHour: hour,
      clockMinute: minute,
      clockQuestion: question,
      clockChoices: s.toList()..shuffle(r),
      clockAnswer: answer,
    );
  }
}
