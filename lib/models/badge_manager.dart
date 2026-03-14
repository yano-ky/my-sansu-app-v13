import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'managers.dart';
import 'math_mode.dart';

// ── バッジ定義 ────────────────────────────────────────────────────────
class BadgeDef {
  final String id;
  final String emoji;
  final String title;
  final String desc;

  const BadgeDef({
    required this.id,
    required this.emoji,
    required this.title,
    required this.desc,
  });
}

const List<BadgeDef> kAllBadges = [
  // はじめて系
  BadgeDef(id: 'first_question', emoji: '🌱', title: 'さいしょの いっぽ', desc: 'はじめて もんだいを といた'),
  BadgeDef(id: 'first_perfect',  emoji: '⭐', title: 'かんぺき！',         desc: 'はじめて ぜんもん せいかい'),

  // 問題数系
  BadgeDef(id: 'solve_10',   emoji: '🔟',  title: '10もん クリア',    desc: 'ぜんぶで 10もん といた'),
  BadgeDef(id: 'solve_50',   emoji: '5️⃣0️⃣', title: '50もん クリア',   desc: 'ぜんぶで 50もん といた'),
  BadgeDef(id: 'solve_100',  emoji: '💯',  title: '100もん クリア',   desc: 'ぜんぶで 100もん といた'),
  BadgeDef(id: 'solve_500',  emoji: '🚀',  title: '500もん クリア',   desc: 'ぜんぶで 500もん といた'),
  BadgeDef(id: 'solve_1000', emoji: '👑',  title: '1000もん クリア',  desc: 'ぜんぶで 1000もん といた'),

  // 連続正解系
  BadgeDef(id: 'streak_3',  emoji: '🔥',  title: '3れんぞく！',   desc: '3かい つづけて せいかい'),
  BadgeDef(id: 'streak_5',  emoji: '🔥🔥', title: '5れんぞく！',  desc: '5かい つづけて せいかい'),
  BadgeDef(id: 'streak_10', emoji: '💥',  title: '10れんぞく！',  desc: '10かい つづけて せいかい'),

  // 継続系
  BadgeDef(id: 'days_3',  emoji: '📅',  title: '3にち れんしゅう',  desc: '3にち つづけて べんきょうした'),
  BadgeDef(id: 'days_7',  emoji: '🗓️',  title: '1しゅうかん！',   desc: '7にち つづけて べんきょうした'),
  BadgeDef(id: 'days_30', emoji: '🏆',  title: '1かげつ かいきん', desc: '30にち つづけて べんきょうした'),

  // モード制覇系
  BadgeDef(id: 'mode_plus',     emoji: '➕', title: 'たしざん はかせ',   desc: 'たしざんで せいかいりつ80%いじょう'),
  BadgeDef(id: 'mode_minus',    emoji: '➖', title: 'ひきざん はかせ',   desc: 'ひきざんで せいかいりつ80%いじょう'),
  BadgeDef(id: 'mode_multi',    emoji: '✖️', title: 'かけざん はかせ',   desc: 'かけざんで せいかいりつ80%いじょう'),
  BadgeDef(id: 'mode_div',      emoji: '➗', title: 'わりざん はかせ',   desc: 'わりざんで せいかいりつ80%いじょう'),
  BadgeDef(id: 'mode_shopping', emoji: '💴', title: 'かいものじょうず',  desc: 'おかいもので せいかいりつ80%いじょう'),
  BadgeDef(id: 'all_modes',     emoji: '🌈', title: 'ぜんぶ はかせ',    desc: 'ぜんモードで せいかいりつ80%いじょう'),

  // タイムアタック系
  BadgeDef(id: 'time_10',  emoji: '⚡',  title: 'タイムアタック10もん', desc: 'タイムアタックで10もん せいかい'),
  BadgeDef(id: 'time_20',  emoji: '⚡⚡', title: 'タイムアタック20もん', desc: 'タイムアタックで20もん せいかい'),

  // 苦手克服系
  BadgeDef(id: 'wrong_clear', emoji: '💪', title: 'にがてを やっつけた！', desc: 'にがてもんだいを ぜんぶ クリア'),
];

// ── BadgeManager ──────────────────────────────────────────────────────
class BadgeManager {
  static const _key = 'earnedBadges';

  static Future<Set<String>> loadEarned() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(_key);
      if (raw == null) return {};
      return Set<String>.from(json.decode(raw) as List);
    } catch (_) { return {}; }
  }

  static Future<List<String>> checkAndGrant({
    required int totalSolved,
    required int streak,
    required bool isPerfect,
    required bool isTimeAttack,
    required int timeAttackScore,
    required bool wrongListCleared,
    required Map<MathMode, Map<String, int>> stats,
  }) async {
    final prefs   = await SharedPreferences.getInstance();
    final earned  = await loadEarned();
    final newBadges = <String>[];

    void grant(String id) {
      if (!earned.contains(id)) { earned.add(id); newBadges.add(id); }
    }

    // はじめて
    if (totalSolved >= 1)    grant('first_question');
    if (isPerfect)           grant('first_perfect');

    // 問題数
    if (totalSolved >= 10)   grant('solve_10');
    if (totalSolved >= 50)   grant('solve_50');
    if (totalSolved >= 100)  grant('solve_100');
    if (totalSolved >= 500)  grant('solve_500');
    if (totalSolved >= 1000) grant('solve_1000');

    // 連続正解
    if (streak >= 3)  grant('streak_3');
    if (streak >= 5)  grant('streak_5');
    if (streak >= 10) grant('streak_10');

    // タイムアタック
    if (isTimeAttack && timeAttackScore >= 10) grant('time_10');
    if (isTimeAttack && timeAttackScore >= 20) grant('time_20');

    // 苦手克服
    if (wrongListCleared) grant('wrong_clear');

    // モード正解率
    final modeMap = {
      'mode_plus':     MathMode.plus,
      'mode_minus':    MathMode.minus,
      'mode_multi':    MathMode.multi,
      'mode_div':      MathMode.div,
      'mode_shopping': MathMode.shopping,
    };
    bool allMaster = true;
    for (final e in modeMap.entries) {
      final d = stats[e.value];
      final total = d?['total'] ?? 0;
      final pct   = total >= 5 ? (d!['correct']! / total) : 0.0;
      if (pct >= 0.8) grant(e.key); else allMaster = false;
    }
    if (allMaster) grant('all_modes');

    // 継続日数
    final cal      = await CalendarManager.loadRecent();
    final streak7  = _calcStreak(cal);
    if (streak7 >= 3)  grant('days_3');
    if (streak7 >= 7)  grant('days_7');
    if (streak7 >= 30) grant('days_30');

    if (newBadges.isNotEmpty) {
      await prefs.setString(_key, json.encode(earned.toList()));
    }
    return newBadges;
  }

  /// カレンダーデータから連続日数を計算
  static int _calcStreak(Map<String, int> cal) {
    final keys = cal.keys.toList()..sort();
    int streak = 0;
    for (int i = keys.length - 1; i >= 0; i--) {
      if ((cal[keys[i]] ?? 0) > 0) streak++;
      else break;
    }
    return streak;
  }

  static Future<int> totalSolved() async {
    final stats = await StatsManager.loadAll();
    return stats.values.fold<int>(0, (s, m) => s + (m['total'] ?? 0));
  }

  static BadgeDef? defById(String id) {
    try { return kAllBadges.firstWhere((b) => b.id == id); }
    catch (_) { return null; }
  }
}

// ── アドバイス ────────────────────────────────────────────────────────
class AdviceManager {
  /// メニュー画面ひとこと（ランダム）
  static String menuAdvice() {
    final list = [
      'きょうも いっしょに がんばろう！',
      'まいにち すこしずつ が たいせつだよ！',
      'まちがえても だいじょうぶ！ つぎに いかそう！',
      'れんしゅうすれば かならず できるようになるよ！',
      'きょうは どのもんだいに ちょうせんする？',
      'むずかしくても あきらめないで！',
      'ゆっくり かんがえて みよう！',
    ];
    list.shuffle();
    return list.first;
  }

  /// 不正解時のアドバイス
  static String wrongAdvice(MathMode mode) {
    final map = {
      MathMode.plus:     'たす ときは、おおきい かずから かぞえると かんたんだよ！',
      MathMode.minus:    'ひく ときは、かずを えや まるで かんがえてみよう！',
      MathMode.multi:    'かけざんは なんかい たすか、ということだよ！',
      MathMode.div:      'わりざんは、おなじかずずつ くばることだよ！',
      MathMode.storyPlus:  'おはなしの かずに せんを ひいて みよう！',
      MathMode.storyMinus: 'のこりは いくつか、かずを えで かいてみよう！',
      MathMode.storyMulti: 'グループの かずを かぞえてみよう！',
      MathMode.storyDiv:   'みんなに こうへいに くばると いくつかな？',
      MathMode.shopping:   'ねだんを たして から かんがえてみよう！',
      MathMode.compare:    'すうじの おおきさ、かずせんで くらべてみよう！',
      MathMode.fillBoth:   'こたえから ぎゃくに かんがえてみよう！',
      MathMode.puzzle:     'いろんな かずを ためして みよう！',
      MathMode.tens:       '10のまとまりが いくつか かぞえてみよう！',
      MathMode.wrong:      'おちついて もう いちど かんがえてみよう！',
      MathMode.challenge:  'もんだいを ゆっくり よんでみよう！',
    };
    return map[mode] ?? 'ゆっくり かんがえてみよう！';
  }

  /// ゲーム終了後の総評
  static String resultAdvice(int pct, int streak) {
    if (pct == 100) return 'かんぺき！ ほんとうに すごいね！👑';
    if (pct >= 80)  return 'とても よくできたね！ この ちょうしで いこう！🎉';
    if (pct >= 60)  return 'がんばったね！ まちがえた もんだいを もう いちど みてみよう！';
    if (streak >= 3) return 'さいごは $streak れんぞく せいかい！ のびてるよ！🔥';
    return 'むずかしかった ね。 れんしゅうすれば かならず できるよ！💪';
  }
}
