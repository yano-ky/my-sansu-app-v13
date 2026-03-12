import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const int kMaxMultiNum = 9;
const int kMaxDivNum = 9;

void main() => runApp(const MathApp());

// ── enum ──────────────────────────────────────────────────────────────
enum MathMode {
  plus, minus, multi, div,
  storyPlus, storyMinus, storyMulti, storyDiv,
  puzzle, wrong,
  shopping, compare, fillBoth, challenge,
  tens;  // 10のまとまり

  bool get isPlus  => this == plus  || this == storyPlus;
  bool get isMinus => this == minus || this == storyMinus;
  bool get isMulti => this == multi || this == storyMulti;
  bool get isDiv   => this == div   || this == storyDiv;

  String get label {
    switch (this) {
      case MathMode.plus:       return 'たしざん';
      case MathMode.minus:      return 'ひきざん';
      case MathMode.multi:      return 'かけざん';
      case MathMode.div:        return 'わりざん';
      case MathMode.storyPlus:  return 'たしざん(ぶんしょう)';
      case MathMode.storyMinus: return 'ひきざん(ぶんしょう)';
      case MathMode.storyMulti: return 'かけざん(ぶんしょう)';
      case MathMode.storyDiv:   return 'わりざん(ぶんしょう)';
      case MathMode.puzzle:     return 'パズル';
      case MathMode.wrong:      return 'にがてこくふく';
      case MathMode.shopping:   return 'おかいもの';
      case MathMode.compare:    return 'かずの おおきさ';
      case MathMode.fillBoth:   return 'むしくいざん';
      case MathMode.challenge:  return 'ちょうせんじょう';
      case MathMode.tens:       return '10の まとまり';
    }
  }

  static MathMode fromString(String s) => MathMode.values.firstWhere(
    (e) => e.name == s, orElse: () => MathMode.plus);
}

// ── 統計管理 ─────────────────────────────────────────────────────────
class StatsManager {
  static Future<void> record(MathMode mode, bool correct) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'stats_${mode.name}';
    Map<String, dynamic> data = {};
    try { data = json.decode(prefs.getString(key) ?? '{}'); } catch (_) {}
    data['correct'] = ((data['correct'] as int?) ?? 0) + (correct ? 1 : 0);
    data['total']   = ((data['total']   as int?) ?? 0) + 1;
    await prefs.setString(key, json.encode(data));
  }

  static Future<Map<MathMode, Map<String, int>>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <MathMode, Map<String, int>>{};
    for (final mode in MathMode.values) {
      if (mode == MathMode.wrong) continue;
      try {
        final raw = prefs.getString('stats_${mode.name}');
        if (raw != null) {
          final d = json.decode(raw);
          result[mode] = {'correct': (d['correct'] as int?) ?? 0, 'total': (d['total'] as int?) ?? 0};
        }
      } catch (_) {}
    }
    return result;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final mode in MathMode.values) await prefs.remove('stats_${mode.name}');
  }
}

// ── 間違い履歴管理（保護者用・消えない） ─────────────────────────────
class HistoryManager {
  static const _key = 'wrongHistory';

  // 間違えたとき呼ぶ：同じ問題なら missCount を +1、なければ追加
  static Future<void> recordWrong(MathMode mode, int n1, int n2, int target) async {
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> history = [];
    try { history = json.decode(prefs.getString(_key) ?? '[]'); } catch (_) {}

    final idx = history.indexWhere((q) =>
        q['m'] == mode.name && q['n1'] == n1 && q['n2'] == n2);
    if (idx >= 0) {
      history[idx]['miss'] = ((history[idx]['miss'] as int?) ?? 1) + 1;
    } else {
      history.add({'m': mode.name, 'n1': n1, 'n2': n2, 't': target, 'miss': 1});
    }
    await prefs.setString(_key, json.encode(history));
  }

  static Future<List<Map<String, dynamic>>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      return List<Map<String, dynamic>>.from(
          (json.decode(raw) as List).map((e) => Map<String, dynamic>.from(e)));
    } catch (_) { return []; }
  }

  // 確認済みにする（dismissed フラグを立てる）
  static Future<void> dismiss(MathMode mode, int n1, int n2) async {
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> history = [];
    try { history = json.decode(prefs.getString(_key) ?? '[]'); } catch (_) {}
    final idx = history.indexWhere((q) =>
        q['m'] == mode.name && q['n1'] == n1 && q['n2'] == n2);
    if (idx >= 0) {
      history[idx]['dismissed'] = true;
      await prefs.setString(_key, json.encode(history));
    }
  }

  // 確認済みを除いてロード（保護者ページのサマリー用）
  static Future<List<Map<String, dynamic>>> loadActive() async {
    final all = await loadAll();
    return all.where((q) => q['dismissed'] != true).toList();
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// ── 学習カレンダー管理 ───────────────────────────────────────────────
class CalendarManager {
  static const _key = 'studyCalendar';

  // 今日の日付キー（例: "2025-06-01"）
  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }

  // 問題を解いたとき呼ぶ（正解・不正解問わず）
  static Future<void> recordQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> data = {};
    try { data = json.decode(prefs.getString(_key) ?? '{}'); } catch (_) {}
    final key = _todayKey();
    data[key] = ((data[key] as int?) ?? 0) + 1;
    await prefs.setString(_key, json.encode(data));
  }

  // 過去 35 日分のデータを {dateKey: count} で返す
  static Future<Map<String, int>> loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> data = {};
    try { data = json.decode(prefs.getString(_key) ?? '{}'); } catch (_) {}
    final result = <String, int>{};
    final now = DateTime.now();
    for (int i = 34; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final k = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      result[k] = (data[k] as int?) ?? 0;
    }
    return result;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// ── 挑戦状管理 ──────────────────────────────────────────────────────
class ChallengeManager {
  static const _key = 'challengeList';

  static Future<List<Map<String, dynamic>>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      return List<Map<String, dynamic>>.from(
          (json.decode(raw) as List).map((e) => Map<String, dynamic>.from(e)));
    } catch (_) { return []; }
  }

  static Future<void> save(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(list));
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class MathApp extends StatelessWidget {
  const MathApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'さんすうアプリ',
    theme: ThemeData(primarySwatch: Colors.orange, useMaterial3: true, fontFamily: 'Hiragino Sans'),
    home: const MenuScreen(),
  );
}

// ── メニュー画面 ──────────────────────────────────────────────────────
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  double maxNum = 10, goal = 10;
  bool isSelect = true;
  bool timeAttack = false;
  List<dynamic> wrongList = [];
  List<Map<String, dynamic>> challengeList = [];
  // 表示するメニューのON/OFF（デフォルトは全部表示）
  Set<String> hiddenModes = {};
  // メニューの表示順（キーのリスト）
  static const _defaultOrder = ['plus','minus','multi','div','story','puzzle','shopping','compare','fillBoth','tens'];
  List<String> menuOrder = List.from(_defaultOrder);

  @override
  void initState() { super.initState(); _loadSettings(); }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> parsed = [];
    try {
      final s = prefs.getString('wrongList');
      if (s != null) parsed = json.decode(s);
    } catch (_) {}
    final cl = await ChallengeManager.loadAll();
    setState(() {
      maxNum     = prefs.getDouble('maxNum')   ?? 10;
      goal       = prefs.getDouble('goal')     ?? 10;
      isSelect   = prefs.getBool('isSelect')   ?? true;
      timeAttack = prefs.getBool('timeAttack') ?? false;
      wrongList  = parsed;
      challengeList = cl;
      hiddenModes = (prefs.getStringList('hiddenModes') ?? []).toSet();
      final savedOrder = prefs.getStringList('menuOrder');
      if (savedOrder != null && savedOrder.length == _defaultOrder.length) {
        menuOrder = savedOrder;
      } else {
        menuOrder = List.from(_defaultOrder);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('さんすうアプリ'),
        backgroundColor: Colors.orange.shade200,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'ほごしゃメニュー',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentPage()));
              _loadSettings();
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.orange.shade50,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (wrongList.isNotEmpty)
                  _menuCard('🔥 にがてを こくふく (${wrongList.length})', Colors.red.shade100, MathMode.wrong),
                ...menuOrder.where((k) => !hiddenModes.contains(k)).map((k) => _menuCardByKey(k)),
                if (challengeList.isNotEmpty)
                  _menuCard('📝 ちょうせんじょう (${challengeList.length}もん)', Colors.deepOrange.shade100, MathMode.challenge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuCardByKey(String key) {
    switch (key) {
      case 'plus':     return _menuCard('➕ たしざん (しき)',          Colors.blue.shade100,       MathMode.plus);
      case 'minus':    return _menuCard('➖ ひきざん (しき)',          Colors.green.shade100,      MathMode.minus);
      case 'multi':    return _menuCard('✖ かけざん (しき)',           Colors.purple.shade100,     MathMode.multi);
      case 'div':      return _menuCard('➗ わりざん (しき)',          Colors.teal.shade100,       MathMode.div);
      case 'story':    return _menuCard('📖 ぶんしょう もんだい',      Colors.orange.shade100,     null, isStoryMenu: true);
      case 'puzzle':   return _menuCard('🧩 しきをつくる パズル',      Colors.yellow.shade200,     null, isPuzzleMenu: true);
      case 'shopping': return _menuCard('💴 おかいもの もんだい',      Colors.pink.shade100,       MathMode.shopping);
      case 'compare':  return _menuCard('🔢 かずの おおきさ くらべ',   Colors.cyan.shade100,       MathMode.compare);
      case 'fillBoth': return _menuCard('🧮 むしくいざん チャレンジ',  Colors.lime.shade200,       null, isFillBothMenu: true);
      case 'tens':     return _menuCard('🔟 10の まとまり',            Colors.teal.shade100,       MathMode.tens);
      default:         return const SizedBox.shrink();
    }
  }

  Widget _menuCard(String title, Color color, MathMode? mode,
      {bool isStoryMenu = false, bool isPuzzleMenu = false, bool isFillBothMenu = false}) {
    return Card(
      color: color,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title, textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        onTap: () async {
          if (isStoryMenu) {
            await Navigator.push(context, MaterialPageRoute(
                builder: (_) => StoryMenuScreen(maxNum: maxNum.toInt(), goal: goal.toInt(), isSelect: isSelect, timeAttack: timeAttack)));
          } else if (isPuzzleMenu) {
            await Navigator.push(context, MaterialPageRoute(
                builder: (_) => PuzzleMenuScreen(maxNum: maxNum.toInt(), goal: goal.toInt(), isSelect: isSelect, timeAttack: timeAttack)));
          } else if (isFillBothMenu) {
            await Navigator.push(context, MaterialPageRoute(
                builder: (_) => FillBothMenuScreen(maxNum: maxNum.toInt(), goal: goal.toInt(), isSelect: isSelect, timeAttack: timeAttack)));
          } else if (mode != null) {
            await Navigator.push(context, MaterialPageRoute(
                builder: (_) => MathGame(mode: mode, maxNum: maxNum.toInt(), goal: goal.toInt(), isSelect: isSelect, timeAttack: timeAttack)));
          }
          _loadSettings();
        },
      ),
    );
  }
}

// ── 保護者ページ ──────────────────────────────────────────────────────
class ParentPage extends StatefulWidget {
  const ParentPage({super.key});
  @override State<ParentPage> createState() => _ParentPageState();
}

class _ParentPageState extends State<ParentPage> {
  double maxNum = 10, goal = 10;
  bool isSelect = true;
  bool timeAttack = false;
  Map<MathMode, Map<String, int>> stats = {};
  List<dynamic> wrongList = [];
  List<Map<String, dynamic>> history = [];
  Set<String> hiddenModes = {};
  List<String> menuOrder = List.from(_MenuScreenState._defaultOrder);

  Map<String, int> calendarData = {};

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final s   = await StatsManager.loadAll();
    final hist = await HistoryManager.loadActive();
    final cal  = await CalendarManager.loadRecent();
    List<dynamic> wl = [];
    try {
      final saved = prefs.getString('wrongList');
      if (saved != null) wl = json.decode(saved);
    } catch (_) {}
    setState(() {
      maxNum      = prefs.getDouble('maxNum')   ?? 10;
      goal        = prefs.getDouble('goal')     ?? 10;
      isSelect    = prefs.getBool('isSelect')   ?? true;
      timeAttack  = prefs.getBool('timeAttack') ?? false;
      stats       = s;
      wrongList   = wl;
      history     = hist;
      hiddenModes = (prefs.getStringList('hiddenModes') ?? []).toSet();
      final savedOrder = prefs.getStringList('menuOrder');
      if (savedOrder != null && savedOrder.length == _MenuScreenState._defaultOrder.length) {
        menuOrder = savedOrder;
      } else {
        menuOrder = List.from(_MenuScreenState._defaultOrder);
      }
      calendarData = cal;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('maxNum', maxNum);
    await prefs.setDouble('goal', goal);
    await prefs.setBool('isSelect', isSelect);
    await prefs.setBool('timeAttack', timeAttack);
    await prefs.setStringList('hiddenModes', hiddenModes.toList());
    await prefs.setStringList('menuOrder', menuOrder);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('保護者メニュー'),
        backgroundColor: Colors.blueGrey.shade200,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.blueGrey.shade50,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _sectionTitle('📅 がくしゅう カレンダー'),
                _buildCalendar(),
                const SizedBox(height: 20),
                _sectionTitle('📊 正解率 グラフ'),
                _buildStatsChart(),
                const SizedBox(height: 20),
                _sectionTitle('📋 間違い 履歴'),
                _buildWeakList(),
                const SizedBox(height: 20),
                _sectionTitle('👁️ メニューの 表示・ならびかえ'),
                _buildVisibilitySettings(),
                const SizedBox(height: 20),
                _sectionTitle('📝 ちょうせんじょう を つくる'),
                _buildChallengeEditor(),
                const SizedBox(height: 20),
                _sectionTitle('⚙️ 問題 設定'),
                _buildSettings(),
                const SizedBox(height: 20),
                _buildResetButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
  );

  Widget _buildCalendar() {
    final entries = calendarData.entries.toList();
    final maxCount = entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    final totalDays = entries.where((e) => e.value > 0).length;
    final todayCount = calendarData[todayKey] ?? 0;

    // 曜日ラベル
    const weekLabels = ['月', '火', '水', '木', '金', '土', '日'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // サマリー行
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: todayCount > 0 ? Colors.orange.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: todayCount > 0 ? Colors.orange.shade200 : Colors.grey.shade200),
              ),
              child: Text('きょう ${todayCount}もん',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                      color: todayCount > 0 ? Colors.orange.shade700 : Colors.grey)),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Text('35日で $totalDays 日れんしゅう',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
            ),
          ]),
          const SizedBox(height: 12),
          // 曜日ヘッダー
          Row(children: weekLabels.map((w) =>
            Expanded(child: Center(child: Text(w,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                    color: w == '日' ? Colors.red.shade400 : w == '土' ? Colors.blue.shade400 : Colors.grey.shade600))))
          ).toList()),
          const SizedBox(height: 4),
          // グリッド（7列×5行）
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisSpacing: 3, crossAxisSpacing: 3, childAspectRatio: 1.1),
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final entry = entries[i];
              final count = entry.value;
              final isToday = entry.key == todayKey;
              final intensity = maxCount == 0 ? 0.0 : count / maxCount;
              Color cellColor;
              if (count == 0)          cellColor = Colors.grey.shade100;
              else if (intensity < 0.33) cellColor = Colors.orange.shade100;
              else if (intensity < 0.66) cellColor = Colors.orange.shade300;
              else                       cellColor = Colors.orange.shade500;

              // 日付の「日」だけ表示
              final dayNum = int.tryParse(entry.key.split('-').last) ?? 0;

              return Tooltip(
                message: '${entry.key}  $count もん',
                child: Container(
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(4),
                    border: isToday
                        ? Border.all(color: Colors.deepOrange, width: 2)
                        : Border.all(color: Colors.grey.shade200, width: 0.5),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('$dayNum',
                        style: TextStyle(
                          fontSize: 10,
                          color: count > 0 ? (intensity >= 0.66 ? Colors.white : Colors.orange.shade900) : Colors.grey.shade400,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        )),
                    if (count > 0)
                      Text('$count',
                          style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.bold,
                            color: intensity >= 0.66 ? Colors.white70 : Colors.orange.shade700,
                          )),
                  ]),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Text('0もん ', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ...[Colors.grey.shade100, Colors.orange.shade100, Colors.orange.shade300, Colors.orange.shade500]
                .map((c) => Container(width: 14, height: 14, margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)))),
            const Text(' おおい', style: TextStyle(fontSize: 10, color: Colors.grey)),
            const Spacer(),
            Container(width: 12, height: 12,
                decoration: BoxDecoration(border: Border.all(color: Colors.deepOrange, width: 2), borderRadius: BorderRadius.circular(2))),
            const Text(' きょう', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
        ]),
      ),
    );
  }
  Widget _buildStatsChart() {
    final modes  = [
      MathMode.plus, MathMode.minus, MathMode.multi, MathMode.div,
      MathMode.storyPlus, MathMode.storyMinus, MathMode.storyMulti, MathMode.storyDiv,
      MathMode.puzzle,
    ];
    final labels = ['たしざん', 'ひきざん', 'かけざん', 'わりざん',
                    'たし(話)', 'ひき(話)', 'かけ(話)', 'わり(話)', 'パズル'];

    if (modes.every((m) => (stats[m]?['total'] ?? 0) == 0)) {
      return const Card(child: Padding(padding: EdgeInsets.all(20),
          child: Center(child: Text('まだ データが ありません', style: TextStyle(color: Colors.grey)))));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(modes.length, (i) {
            final mode    = modes[i];
            final total   = stats[mode]?['total']   ?? 0;
            final correct = stats[mode]?['correct'] ?? 0;
            final rate    = total == 0 ? 0.0 : correct / total;
            final pct     = (rate * 100).round();
            final barColor = pct >= 80 ? Colors.green : pct >= 50 ? Colors.orange : Colors.red;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(width: 52, child: Text(labels[i], style: const TextStyle(fontSize: 12))),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: rate, minHeight: 20,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(width: 80,
                    child: Text(total == 0 ? '－' : '$pct% ($correct/$total)',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700))),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildWeakList() {
    if (history.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16),
          child: Center(child: Text('まだ 間違いがありません 🎉', style: TextStyle(color: Colors.grey)))));
    }

    final totalMiss = history.fold<int>(0, (sum, q) => sum + ((q['miss'] as int?) ?? 1));
    final hotCount  = history.where((q) => ((q['miss'] as int?) ?? 1) >= 3).length;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(
              builder: (_) => HistoryPage(history: history)));
          _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blueGrey.shade200),
                    ),
                    child: Text('${history.length} もん きろく',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text('のべ $totalMiss かいまちがい',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                  ),
                ]),
                if (hotCount > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text('🔴 $hotCount もん が3かい以上まちがい',
                        style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ],
                const SizedBox(height: 6),
                const Text('▶ くわしくみる',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: Colors.blueGrey),
          ]),
        ),
      ),
    );
  }

  Widget _buildVisibilitySettings() {
    const labelMap = {
      'plus':     '➕ たしざん',
      'minus':    '➖ ひきざん',
      'multi':    '✖ かけざん',
      'div':      '➗ わりざん',
      'story':    '📖 ぶんしょう もんだい',
      'puzzle':   '🧩 パズル',
      'shopping': '💴 おかいもの',
      'compare':  '🔢 かずの おおきさ',
      'fillBoth': '🧮 むしくいざん',
      'tens':     '🔟 10の まとまり',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(children: [
                Icon(Icons.drag_indicator, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text('ドラッグで ならびかえ できます',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ]),
            ),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = menuOrder.removeAt(oldIndex);
                  menuOrder.insert(newIndex, item);
                });
                _save();
              },
              children: menuOrder.map((key) {
                final label = labelMap[key] ?? key;
                final isVisible = !hiddenModes.contains(key);
                return Material(
                  key: ValueKey(key),
                  color: Colors.transparent,
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.only(left: 12, right: 4),
                    title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(isVisible ? 'メニューに表示' : '隠している',
                        style: TextStyle(fontSize: 11,
                            color: isVisible ? Colors.green.shade600 : Colors.grey)),
                    secondary: Icon(Icons.drag_handle, color: Colors.grey.shade400),
                    value: isVisible,
                    activeColor: Colors.orange,
                    onChanged: (v) {
                      setState(() {
                        if (v) hiddenModes.remove(key);
                        else   hiddenModes.add(key);
                      });
                      _save();
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: StatefulBuilder(builder: (context, setS) {
          final v = maxNum.round();
          String levelName; Color levelColor;
          if (v <= 10)      { levelName = '1桁';           levelColor = Colors.blue; }
          else if (v <= 20) { levelName = '少し2桁';     levelColor = Colors.green; }
          else if (v <= 50) { levelName = '2桁・普通';   levelColor = Colors.orange; }
          else              { levelName = '2桁・難しい'; levelColor = Colors.red; }

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🔢 難しさ', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Row(children: [
              Text('$v まで', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: levelColor)),
              const SizedBox(width: 8),
              Text('($levelName)', style: TextStyle(fontSize: 12, color: levelColor)),
            ]),
            Slider(value: maxNum, min: 10, max: 100, divisions: 9, activeColor: levelColor,
              onChanged: (val) { setS(() => maxNum = val); setState(() {}); },
              onChangeEnd: (_) => _save()),
            const Divider(),
            const Text('🏁 問題数', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('${goal.toInt()} 問',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            Slider(value: goal, min: 5, max: 50, divisions: 9,
              onChanged: (val) { setS(() => goal = val); setState(() {}); },
              onChangeEnd: (_) => _save()),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('⏱️ タイムアタック', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(timeAttack ? '30秒で何問解けるか挑戦！' : 'タイムアタックOFF',
                  style: const TextStyle(fontSize: 11)),
              value: timeAttack,
              onChanged: (v) { setS(() => timeAttack = v); setState(() {}); _save(); },
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('🔘 選ぶモード', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(isSelect ? '答えを4つから選ぶ' : '数字を自分で打つ',
                  style: const TextStyle(fontSize: 11)),
              value: isSelect,
              onChanged: (v) { setS(() => isSelect = v); setState(() {}); _save(); },
            ),
          ]);
        }),
      ),
    );
  }

  Widget _buildChallengeEditor() {
    final fromCtrl  = TextEditingController();
    final msgCtrl   = TextEditingController();
    final qCtrl     = TextEditingController();
    final ansCtrl   = TextEditingController();
    return StatefulBuilder(builder: (context, setS) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 既存リスト
            FutureBuilder<List<Map<String, dynamic>>>(
              future: ChallengeManager.loadAll(),
              builder: (ctx, snap) {
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('まだ ちょうせんじょうが ありません',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('登録済み ${list.length} 問',
                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    const SizedBox(height: 6),
                    ...list.asMap().entries.map((e) {
                      final i = e.key; final item = e.value;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14, backgroundColor: Colors.deepOrange.shade100,
                          child: Text('${i+1}', style: const TextStyle(fontSize: 11)),
                        ),
                        title: Text(item['question'] as String? ?? '',
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('答え: ${item["answer"]}  from: ${item["from"] ?? ""}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () async {
                            final newList = List<Map<String, dynamic>>.from(list)..removeAt(i);
                            await ChallengeManager.save(newList);
                            setS(() {});
                          },
                        ),
                      );
                    }),
                    const Divider(),
                  ],
                );
              },
            ),
            // 入力フォーム
            const Text('＋ あたらしく つくる',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 10),
            TextField(
              controller: fromCtrl,
              decoration: const InputDecoration(
                labelText: '差出人（例：パパ、ママ）',
                border: OutlineInputBorder(), isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: msgCtrl,
              decoration: const InputDecoration(
                labelText: 'ひとことメッセージ（任意）',
                hintText: '例：がんばれ！パパより',
                border: OutlineInputBorder(), isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: qCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '問題文',
                hintText: '例：12＋34は？',
                border: OutlineInputBorder(), isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ansCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '答え（数字）',
                border: OutlineInputBorder(), isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('ちょうせんじょうに 追加'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
                onPressed: () async {
                  final ans = int.tryParse(ansCtrl.text);
                  if (qCtrl.text.isEmpty || ans == null) return;
                  final list = await ChallengeManager.loadAll();
                  list.add({
                    'from': fromCtrl.text.isEmpty ? 'パパ・ママ' : fromCtrl.text,
                    'message': msgCtrl.text,
                    'question': qCtrl.text,
                    'answer': ans,
                  });
                  await ChallengeManager.save(list);
                  fromCtrl.clear(); msgCtrl.clear(); qCtrl.clear(); ansCtrl.clear();
                  setS(() {});
                },
              ),
            ),
          ]),
        ),
      );
    });
  }

  Widget _buildResetButton() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
      icon: const Icon(Icons.delete_forever),
      label: const Text('記録を すべて リセット'),
      onPressed: () async {
        final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
          title: const Text('リセットしますか？'),
          content: const Text('正解率・にがてリストが 全て消えます。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('キャンセル')),
            TextButton(onPressed: () => Navigator.pop(c, true),
                child: const Text('リセット', style: TextStyle(color: Colors.red))),
          ],
        ));
        if (ok == true) {
          await StatsManager.clearAll();
          await HistoryManager.clearAll();
          await CalendarManager.clearAll();
          await ChallengeManager.clearAll();
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('wrongList');
          _load();
        }
      },
    );
  }
}

// ── ストーリーメニュー ────────────────────────────────────────────────
class StoryMenuScreen extends StatelessWidget {
  final int maxNum, goal; final bool isSelect; final bool timeAttack;
  const StoryMenuScreen({super.key, required this.maxNum, required this.goal, required this.isSelect, this.timeAttack = false});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('どの おはなし？'), backgroundColor: Colors.orange.shade200, centerTitle: true),
    body: Container(color: Colors.orange.shade50, child: ListView(padding: const EdgeInsets.all(20), children: [
      _s(context, '➕ たしざん おはなし', MathMode.storyPlus,  Colors.blue.shade100),
      _s(context, '➖ ひきざん おはなし', MathMode.storyMinus, Colors.green.shade100),
      _s(context, '✖ かけざん おはなし',  MathMode.storyMulti, Colors.purple.shade100),
      _s(context, '➗ わりざん おはなし', MathMode.storyDiv,   Colors.teal.shade100),
    ])),
  );
  Widget _s(BuildContext ctx, String t, MathMode m, Color c) => Card(color: c,
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: ListTile(title: Text(t, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: () => Navigator.push(ctx, MaterialPageRoute(
          builder: (_) => MathGame(mode: m, maxNum: maxNum, goal: goal, isSelect: isSelect, timeAttack: timeAttack)))));
}

// ── パズルメニュー ───────────────────────────────────────────────────
class PuzzleMenuScreen extends StatelessWidget {
  final int maxNum, goal; final bool isSelect; final bool timeAttack;
  const PuzzleMenuScreen({super.key, required this.maxNum, required this.goal, required this.isSelect, this.timeAttack = false});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('パズルに ちょうせん！'), backgroundColor: Colors.orange.shade200, centerTitle: true),
    body: Container(color: Colors.orange.shade50, child: ListView(padding: const EdgeInsets.all(20), children: [
      _p(context, '➕ たしざん パズル',       Colors.green.shade100,  1),
      _p(context, '➖ ひきざん パズル',       Colors.blue.shade100,   2),
      _p(context, '➕➕ 3つの たしざん',     Colors.purple.shade100, 3),
      _p(context, '🌀 ぜんぶ まざった パズル', Colors.red.shade100,   4),
    ])),
  );
  Widget _p(BuildContext ctx, String t, Color c, int lv) => Card(color: c,
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: ListTile(title: Text(t, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: () => Navigator.push(ctx, MaterialPageRoute(
          builder: (_) => MathGame(mode: MathMode.puzzle, maxNum: maxNum, goal: goal, isSelect: isSelect, timeAttack: timeAttack, pLv: lv)))));
}

// ── むしくいざんメニュー ───────────────────────────────────────────────
class FillBothMenuScreen extends StatelessWidget {
  final int maxNum, goal; final bool isSelect; final bool timeAttack;
  const FillBothMenuScreen({super.key, required this.maxNum, required this.goal, required this.isSelect, this.timeAttack = false});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('レベルを えらぼう'), backgroundColor: Colors.lime.shade300, centerTitle: true),
    body: Container(color: Colors.lime.shade50, child: ListView(padding: const EdgeInsets.all(20), children: [
      _f(context, '➕ たしざんだけ',          Colors.green.shade100,  1),
      _f(context, '➖ ひきざんだけ',          Colors.blue.shade100,   2),
      _f(context, '✖ かけざんだけ',           Colors.purple.shade100, 3),
      _f(context, '➗ わりざんだけ',          Colors.teal.shade100,   4),
      _f(context, '🌀 ぜんぶ まざった',       Colors.orange.shade100, 5),
    ])),
  );
  Widget _f(BuildContext ctx, String t, Color c, int lv) => Card(color: c,
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: ListTile(title: Text(t, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      onTap: () => Navigator.push(ctx, MaterialPageRoute(
          builder: (_) => MathGame(mode: MathMode.fillBoth, maxNum: maxNum, goal: goal, isSelect: isSelect, timeAttack: timeAttack, fillBothLv: lv)))));
}

// ── ゲーム画面 ───────────────────────────────────────────────────────
class MathGame extends StatefulWidget {
  final MathMode mode; final int maxNum, goal; final bool isSelect; final int pLv; final int fillBothLv; final bool timeAttack;
  const MathGame({super.key, required this.mode, required this.maxNum, required this.goal,
      required this.isSelect, this.pLv = 1, this.fillBothLv = 0, this.timeAttack = false});
  @override State<MathGame> createState() => _MathGameState();
}

class _MathGameState extends State<MathGame> {
  late MathMode curM;
  String pOp = '＋', emoji = '🍓', story = '';
  int n1 = 0, n2 = 0, target = 0, curQ = 1;
  List<int?> slots = []; List<int> choices = [];
  bool hint = false, showTable = false;
  int hintLevel = 0;
  int correctCount = 0, wrongCount = 0;
  int streak = 0;
  List<dynamic> wList = [];
  final TextEditingController _ansCtrl = TextEditingController();

  // おかいもの問題
  int shopPrice = 0, shopPaid = 0, shopChange = 0;
  int shopPriceA = 0, shopPriceB = 0; // 各商品の値段
  bool shopIsChange = false;
  String shopItemA = '', shopItemB = '';

  // 数の大小比較
  int cmpA = 0, cmpB = 0;
  String correctSign = ''; // '<' or '>'
  List<String> cmpChoices = [];

  // 虫食い算強化
  String fillOp = '＋';
  int fillA = 0, fillB = 0, fillAns = 0;
  bool fillIsLeft = true;
  List<int> fillChoices = [];

  // 10のまとまり
  int tensBlocks = 0, tensOnes = 0; // 何十＋何
  int tensTarget = 0;               // 答えの数
  bool tensAskTotal = true;         // true=合計を答える, false=まとまりの数を答える
  List<int> tensChoices = [];

  // 挑戦状
  List<Map<String, dynamic>> _challengeList = [];
  int _challengeIdx = 0;

  // 4. タイムアタック用
  int _timeLeft = 30;
  bool _timerRunning = false;
  // ignore: cancel_subscriptions
  dynamic _timer; // Timer型だがimportなしでも動くようにdynamicで宣言

  // 3. キャラクター状態

  @override void dispose() {
    _ansCtrl.dispose();
    _stopTimer();
    super.dispose();
  }

  @override void initState() {
    super.initState();
    curM = widget.mode;
    if (curM == MathMode.wrong) _loadWrongList();
    else if (curM == MathMode.challenge) _loadChallengeList();
    else {
      _generateQuestion();
      if (widget.timeAttack) _startTimer();
    }
  }

  Future<void> _loadChallengeList() async {
    final list = await ChallengeManager.loadAll();
    if (!mounted) return;
    if (list.isEmpty) { Navigator.pop(context); return; }
    setState(() { _challengeList = list; _challengeIdx = 0; });
    _generateQuestion();
    if (widget.timeAttack) _startTimer();
  }

  void _startTimer() {
    _timeLeft = 30;
    _timerRunning = true;
    // 毎秒カウントダウン
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_timerRunning) return false;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        _timerRunning = false;
        _finishGame();
        return false;
      }
      return true;
    });
  }

  void _stopTimer() { _timerRunning = false; }

  Future<void> _loadWrongList() async {
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> parsed = [];
    try { final d = prefs.getString('wrongList'); if (d != null) parsed = json.decode(d); } catch (_) {}
    if (!mounted) return;
    setState(() { wList = parsed; });
    if (wList.isEmpty) Navigator.pop(context);
    else {
      _generateQuestion();
      if (widget.timeAttack) _startTimer();
    }
  }

  void _generateQuestion() {
    final r = Random(); showTable = false;
    if (widget.mode == MathMode.wrong) {
      if (wList.isEmpty) { _finishGame(); return; }
      final q = wList[0];
      curM = MathMode.fromString(q['m'] as String);
      n1 = q['n1'] as int; n2 = q['n2'] as int; target = q['t'] as int;
      // shoppingの場合は金額・商品情報を復元
      if (curM == MathMode.shopping) {
        shopPriceA  = (q['priceA']   as int?) ?? target;
        shopPriceB  = (q['priceB']   as int?) ?? 0;
        shopItemA   = (q['itemA']    as String?) ?? '🛒 しょうひん A';
        shopItemB   = (q['itemB']    as String?) ?? '🛒 しょうひん B';
        shopIsChange = (q['isChange'] as int?) == 1;
        shopPrice   = shopPriceA + shopPriceB;
        shopPaid    = (q['paid'] as int?) ?? shopPrice + 100;
        shopChange  = shopPaid - shopPrice;
        target      = shopIsChange ? shopChange : shopPrice;
        // 選択肢再生成
        final rng = Random();
        final ws = <int>{target};
        int att = 0;
        while (ws.length < 4 && att < 200) { att++; final d = target + (rng.nextInt(11) - 5) * 10; if (d > 0 && d != target) ws.add(d); }
        for (int i = 10; ws.length < 4; i += 10) { if (!ws.contains(target + i)) ws.add(target + i); }
        choices = [target, ...ws.where((v) => v != target)]..shuffle(rng);
        if (choices.length > 4) choices = choices.sublist(0, 4);
        _ansCtrl.clear(); hint = false; hintLevel = 0; setState(() {}); return;
      }
      // compareの場合はcmpA/cmpBを復元
      if (curM == MathMode.compare) {
        cmpA = n1; cmpB = n2;
        correctSign = cmpA > cmpB ? '＞' : '＜';
        cmpChoices = ['＞', '＜']..shuffle();
        hint = false; hintLevel = 0; setState(() {}); return;
      }
      // fillBothの場合はfillA/fillB/fillAns/fillOpも復元
      if (curM == MathMode.fillBoth) {
        fillA = n1; fillB = n2; fillAns = target;
        // 保存済みのop/isLeftを使う、なければ逆算
        if (q['op'] != null) {
          fillOp = q['op'] as String;
        } else {
          if (n1 + n2 == target) fillOp = '＋';
          else if (n1 - n2 == target) fillOp = '－';
          else if (n1 * n2 == target) fillOp = '×';
          else fillOp = '÷';
        }
        fillIsLeft = (q['isLeft'] as int?) != 0;
        // 選択肢生成
        final wrongSet = <int>{target};
        int att = 0;
        while (wrongSet.length < 4 && att < 100) { att++; final d = target + r.nextInt(10) - 4; if (d >= 1 && d != target) wrongSet.add(d); }
        for (int i = 1; wrongSet.length < 4; i++) { if (!wrongSet.contains(target + i)) wrongSet.add(target + i); else if (!wrongSet.contains(target - i) && target - i >= 1) wrongSet.add(target - i); }
        fillChoices = wrongSet.toList()..shuffle();
        _ansCtrl.clear(); hint = false; hintLevel = 0; setState(() {}); return;
      }
    } else if (curM == MathMode.challenge) {
      if (_challengeIdx >= _challengeList.length) { _finishGame(); return; }
      // 挑戦状は _buildChallengeUI で直接データを使うので target だけセット
      target = _challengeList[_challengeIdx]['answer'] as int;
      _ansCtrl.clear(); hint = false; hintLevel = 0; setState(() {}); return;
    } else if (curM == MathMode.shopping) {
      _genShopping(r);
      _ansCtrl.clear(); hint = false; hintLevel = 0; setState(() {}); return;
    } else if (curM == MathMode.compare) {
      if (curQ > widget.goal) { _finishGame(); return; }
      _genCompare(r);
      setState(() {}); return;
    } else if (curM == MathMode.fillBoth) {
      if (curQ > widget.goal) { _finishGame(); return; }
      _genFillBoth(r);
      _ansCtrl.clear(); hint = false; hintLevel = 0; setState(() {}); return;
    } else if (curM == MathMode.tens) {
      if (curQ > widget.goal) { _finishGame(); return; }
      _genTens(r);
      _ansCtrl.clear(); hint = false; hintLevel = 0; setState(() {}); return;
    } else {
      if (curQ > widget.goal) { _finishGame(); return; }
      if (curM == MathMode.puzzle) {
        _genPuzzle(r);
      } else if (curM.isPlus) {
        n1 = r.nextInt(widget.maxNum) + 1; n2 = r.nextInt(widget.maxNum) + 1; target = n1 + n2;
      } else if (curM.isMinus) {
        n1 = r.nextInt(widget.maxNum) + 5; n2 = r.nextInt(n1 - 1) + 1; target = n1 - n2;
      } else if (curM.isMulti) {
        n1 = r.nextInt(kMaxMultiNum) + 1; n2 = r.nextInt(kMaxMultiNum) + 1; target = n1 * n2;
      } else if (curM.isDiv) {
        target = r.nextInt(kMaxDivNum) + 1; n2 = r.nextInt(kMaxDivNum) + 1; n1 = target * n2;
      }
    }
    _setRandomStory(); _ansCtrl.clear(); hint = false; hintLevel = 0; _setupChoices(r); setState(() {});
  }

  // おかいもの問題生成
  void _genShopping(Random r) {
    final items = [
      ('🍬 アメ', 10), ('🍪 クッキー', 30), ('🍫 チョコ', 50),
      ('📏 えんぴつ', 60), ('📓 ノート', 80), ('🧃 ジュース', 120),
      ('🍞 パン', 150), ('🖊️ ペン', 200),
    ];
    shopIsChange = widget.isSelect ? r.nextBool() : r.nextBool();
    final a = items[r.nextInt(items.length)];
    final b = items[r.nextInt(items.length)];
    shopItemA = a.$1; shopItemB = b.$1;
    shopPriceA = a.$2; shopPriceB = b.$2;
    final priceA = a.$2; final priceB = b.$2;
    shopPrice = priceA + priceB;
    if (shopIsChange) {
      // おつり問題：払う金額を決める（きりのいい数）
      final units = [100, 200, 300, 500, 1000];
      shopPaid = units.firstWhere((u) => u > shopPrice, orElse: () => 1000);
      shopChange = shopPaid - shopPrice;
      target = shopChange;
    } else {
      target = shopPrice;
    }
    // 選択肢
    final wrong = <int>{target};
    while (wrong.length < 4) {
      final d = target + (r.nextInt(11) - 5) * 10;
      if (d > 0 && d != target) wrong.add(d);
    }
    choices = wrong.toList()..shuffle();
  }

  // 数の大小比較生成
  void _genCompare(Random r) {
    cmpA = r.nextInt(widget.maxNum) + 1;
    cmpB = r.nextInt(widget.maxNum) + 1;
    while (cmpA == cmpB) cmpB = r.nextInt(widget.maxNum) + 1;
    correctSign = cmpA > cmpB ? '＞' : '＜';
    cmpChoices = ['＞', '＜']..shuffle();
  }

  // 虫食い算強化生成
  void _genFillBoth(Random r) {
    final lv = widget.fillBothLv;
    // lv: 0=全部(デフォルト), 1=＋のみ, 2=－のみ, 3=×のみ, 4=÷のみ, 5=全部
    List<String> ops;
    if (lv == 1)      ops = ['＋'];
    else if (lv == 2) ops = ['－'];
    else if (lv == 3) ops = ['×'];
    else if (lv == 4) ops = ['÷'];
    else              ops = ['＋', '－', '×', '÷'];
    fillOp = ops[r.nextInt(ops.length)];
    fillIsLeft = r.nextBool(); // □が左か右か
    switch (fillOp) {
      case '＋':
        fillA = r.nextInt(widget.maxNum) + 1;
        fillB = r.nextInt(widget.maxNum) + 1;
        fillAns = fillIsLeft ? fillA : fillB; // 答えは□の値
        break;
      case '－':
        fillA = r.nextInt(widget.maxNum) + 5;
        fillB = r.nextInt(fillA - 1) + 1;
        fillAns = fillIsLeft ? fillA : fillB;
        break;
      case '×':
        fillA = r.nextInt(kMaxMultiNum) + 1;
        fillB = r.nextInt(kMaxMultiNum) + 1;
        fillAns = fillIsLeft ? fillA : fillB;
        break;
      case '÷':
        fillAns = r.nextInt(kMaxDivNum) + 1;
        fillB = r.nextInt(kMaxDivNum) + 1;
        fillA = fillAns * fillB;
        if (!fillIsLeft) fillAns = fillB; // 右が□なら÷の右辺
        break;
    }
    target = fillAns;
    // 選択肢
    final wrongSet = <int>{target};
    int attempts = 0;
    while (wrongSet.length < 4 && attempts < 100) {
      attempts++;
      final d = target + r.nextInt(10) - 4;
      if (d >= 1 && d != target) wrongSet.add(d);
    }
    for (int i = 1; wrongSet.length < 4; i++) {
      if (!wrongSet.contains(target + i)) wrongSet.add(target + i);
      else if (!wrongSet.contains(target - i) && target - i >= 1) wrongSet.add(target - i);
    }
    fillChoices = wrongSet.toList()..shuffle();
  }

  void _genTens(Random r) {
    tensBlocks = r.nextInt(9) + 1;  // 1〜9のまとまり
    tensOnes   = r.nextInt(10);     // 0〜9のバラ
    tensAskTotal = r.nextBool();    // 合計を聞くか、まとまりの数を聞くか
    if (tensAskTotal) {
      tensTarget = tensBlocks * 10 + tensOnes;
    } else {
      tensTarget = tensBlocks; // 「10がいくつ？」を聞く
    }
    target = tensTarget;
    // ダミー選択肢を3つ生成（targetとは完全に別に）
    final dummies = <int>{};
    int attempts = 0;
    while (dummies.length < 3 && attempts < 200) {
      attempts++;
      final d = target + r.nextInt(9) - 4;
      if (d >= 1 && d != target) dummies.add(d);
    }
    // 強制補充
    for (int i = 1; dummies.length < 3; i++) {
      if (!dummies.contains(target + i)) dummies.add(target + i);
      else if (target - i >= 1 && !dummies.contains(target - i)) dummies.add(target - i);
    }
    // targetを必ず含む4択を作りシャッフル
    tensChoices = [target, ...dummies]..shuffle(r);
  }

  void _genPuzzle(Random r) {
    if (widget.pLv == 4) {
      final type = r.nextInt(4);
      if (type == 0)      { pOp = '＋'; n1 = r.nextInt(20)+1; n2 = r.nextInt(20)+1; target = n1+n2; }
      else if (type == 1) { pOp = '－'; n1 = r.nextInt(20)+10; n2 = r.nextInt(n1-1)+1; target = n1-n2; }
      else if (type == 2) { pOp = '×'; n1 = r.nextInt(kMaxMultiNum)+1; n2 = r.nextInt(kMaxMultiNum)+1; target = n1*n2; }
      else                { pOp = '÷'; target = r.nextInt(kMaxDivNum)+1; n2 = r.nextInt(kMaxDivNum)+1; n1 = target*n2; }
      slots = List.filled(2, null);
    } else {
      pOp   = widget.pLv == 2 ? '－' : '＋';
      slots = List.filled(widget.pLv == 3 ? 3 : 2, null);
      target = widget.pLv == 3 ? r.nextInt(15)+5 : r.nextInt(15)+2;
    }
  }

  void _setupChoices(Random r) {
    choices = [target];
    while (choices.length < 4) { final d = target+r.nextInt(10)-5; if (d>=1 && !choices.contains(d)) choices.add(d); }
    choices.shuffle();
  }

  void _setRandomStory() {
    final r = Random();
    final names    = ['たろうくん','はなこちゃん','うさぎさん','おとうさん','おかあさん','くまさん','パンダくん'];
    final itemDict = {'アメ':'🍬','どんぐり':'🌰','シール':'⭐','いちご':'🍓','クッキー':'🍪','チョコ':'🍫'};
    final itemName = itemDict.keys.toList()[r.nextInt(itemDict.length)];
    emoji = itemDict[itemName]!;
    final name = names[r.nextInt(names.length)];
    if (curM == MathMode.storyPlus)  story = '$name は $itemName を $n1 こ もっていました。\nあとから $n2 こ もらうと、ぜんぶで なんこ？';
    else if (curM == MathMode.storyMinus) story = '$name は $itemName を $n1 こ もっていました。\n$n2 こ おともだちに あげると、のこりは なんこ？';
    else if (curM == MathMode.storyMulti) story = 'さらが $n1 まい あります。\n1まいの さらに $itemName を $n2 こずつ いれると、ぜんぶで なんこ？';
    else if (curM == MathMode.storyDiv)   story = '$n1 こ の $itemName を、$n2 にんで おなじかずずつ わけると、ひとり なんこ？';
    else story = '';
  }

  Future<void> _checkAnswer(bool ok) async {
    await StatsManager.record(curM, ok);
    await CalendarManager.recordQuestion(); // 5. カレンダー記録
    if (ok) {
      correctCount++;
      streak++;          // 3. ストリーク加算
    } else {
      wrongCount++;
      streak = 0;        // 3. ストリークリセット
    }
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> list = [];
    try { list = json.decode(prefs.getString('wrongList') ?? '[]'); } catch (_) {}
    if (ok) {
      if (widget.mode == MathMode.wrong) {
        if (list.isNotEmpty) list.removeAt(0);
        await prefs.setString('wrongList', json.encode(list));
        setState(() { if (wList.isNotEmpty) wList.removeAt(0); });
      }
    } else if (widget.mode != MathMode.wrong) {
      // fillBoth は fillA/fillB、compare は cmpA/cmpB、shopping は shopPrice/shopPaid を保存
      final saveN1 = (curM == MathMode.fillBoth) ? fillA
                   : (curM == MathMode.compare)  ? cmpA
                   : (curM == MathMode.shopping) ? shopPriceA
                   : n1;
      final saveN2 = (curM == MathMode.fillBoth) ? fillB
                   : (curM == MathMode.compare)  ? cmpB
                   : (curM == MathMode.shopping) ? shopPriceB
                   : n2;
      final saveT  = target;
      // challenge/tens はにがてリストに入れない
      final canSaveWrong = curM != MathMode.challenge && curM != MathMode.tens;
      if (canSaveWrong) {
        final saveKey = (curM == MathMode.shopping)
            ? list.any((q) => q['m'] == curM.name && q['t'] == saveT && q['paid'] == shopPaid)
            : list.any((q) => q['m'] == curM.name && q['n1'] == saveN1 && q['n2'] == saveN2);
        if (!saveKey) {
          final entry = {'m': curM.name, 'n1': saveN1, 'n2': saveN2, 't': saveT};
          if (curM == MathMode.fillBoth) {
            entry['op'] = fillOp;
            entry['isLeft'] = fillIsLeft ? 1 : 0;
          }
          if (curM == MathMode.shopping) {
            entry['paid']     = shopPaid;
            entry['isChange'] = shopIsChange ? 1 : 0;
            entry['priceA']   = shopPriceA;
            entry['priceB']   = shopPriceB;
            entry['itemA']    = shopItemA;
            entry['itemB']    = shopItemB;
          }
          list.add(entry);
          await prefs.setString('wrongList', json.encode(list));
        }
        await HistoryManager.recordWrong(curM, saveN1, saveN2, saveT);
      }
    }
    _showResultDialog(ok);
  }

  void _showResultDialog(bool ok) {
    showDialog(context: context, barrierDismissible: false, builder: (c) {
      if (ok) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && Navigator.canPop(c)) {
            Navigator.pop(c);
            if (widget.mode == MathMode.wrong) {
              if (wList.isEmpty) _finishGame(); else _generateQuestion();
            } else if (curM == MathMode.challenge) {
              _challengeIdx++;
              if (_challengeIdx >= _challengeList.length) _finishGame();
              else _generateQuestion();
            } else if (!widget.timeAttack) {
              curQ++;
              _generateQuestion();
            } else {
              _generateQuestion();
            }
          }
        });
      } else {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted && Navigator.canPop(c)) {
            Navigator.pop(c);
          }
        });
      }
      return AlertDialog(
        backgroundColor: ok ? Colors.orange : Colors.blueGrey,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(ok ? '✨ せいかい！ ✨' : '❌ おしい！', textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ),
        content: ok && streak >= 3
            ? Text('🔥 $streak かいつづいてるよ！', textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))
            : null,
        actions: ok ? null : [Center(child: TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('もういちど', style: TextStyle(color: Colors.white))))],
      );
    });
  }

  void _finishGame() {
    _stopTimer();
    final total = correctCount + wrongCount;
    final pct   = total == 0 ? 0 : (correctCount * 100 / total).round();
    String comment; String medal;
    if (pct == 100)      { comment = 'かんぺき！ すごすぎる！';   medal = '🥇'; }
    else if (pct >= 80)  { comment = 'すばらしい！ よくできたね！'; medal = '🥈'; }
    else if (pct >= 50)  { comment = 'よくがんばったね！';         medal = '🥉'; }
    else                 { comment = 'つぎは もっと できるよ！';   medal = '⭐'; }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Center(child: Text(
            widget.timeAttack ? '⏱️ タイムアップ！' : '🎊 おわったよ！ 🎊',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold))),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(medal, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 8),
          Text(comment, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          if (widget.timeAttack)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('30びょうで $correctCount もん せいかい！',
                  style: TextStyle(fontSize: 15, color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
            ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _resultItem('✅ せいかい', correctCount, Colors.green),
                Container(width: 1, height: 44, color: Colors.orange.shade200),
                _resultItem('❌ ふせいかい', wrongCount, Colors.red),
              ]),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Colors.orange.shade200, height: 1),
              ),
              _resultItem('📊 せいかいりつ', pct, Colors.blue, suffix: '%'),
            ]),
          ),
          const SizedBox(height: 20),
        ]),
        actions: [
          Center(child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () { Navigator.pop(c); Navigator.pop(context); },
            child: const Text('もどる', style: TextStyle(fontSize: 16)),
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _resultItem(String label, int value, Color color, {String suffix = 'もん'}) {
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      const SizedBox(height: 4),
      Text('$value$suffix', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    String op = '＋';
    if (curM.isMinus) op = '－'; else if (curM.isMulti) op = '×'; else if (curM.isDiv) op = '÷';
    final titleText = widget.timeAttack
        ? '⏱️ ${"$_timeLeft".padLeft(2,'0')} びょう　$correctCount もん'
        : widget.mode == MathMode.wrong
            ? '🔥 にがてを こくふく\n(のこり ${wList.length} もん)'
            : widget.mode == MathMode.challenge && _challengeList.isNotEmpty && _challengeIdx < _challengeList.length
                ? '📝 ${_challengeList[_challengeIdx]['from'] ?? 'ちょうせんじょう'} からの ちょうせん！'
                : 'だい $curQ もん / ${widget.goal} もん';
    final progress = widget.timeAttack
        ? _timeLeft / 30
        : widget.mode == MathMode.wrong ? 0.0 : (curQ - 1) / widget.goal;
    final timerColor = _timeLeft <= 10 ? Colors.red : Colors.orange;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: widget.timeAttack && _timeLeft <= 10
            ? Colors.red.shade200
            : Colors.orange.shade200,
        title: FittedBox(fit: BoxFit.scaleDown,
            child: Text(titleText, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2))),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.orange.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(
                widget.timeAttack ? timerColor : Colors.orange))),
      ),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(child: Column(children: [
          if (curM == MathMode.puzzle)        _buildPuzzleUI()
          else if (curM == MathMode.shopping) _buildShoppingUI()
          else if (curM == MathMode.compare)  _buildCompareUI()
          else if (curM == MathMode.fillBoth) _buildFillBothUI()
          else if (curM == MathMode.tens)     _buildTensUI()
          else if (curM == MathMode.challenge) _buildChallengeUI()
          else _buildNormalUI(op),
          if (curM.isMulti) ...[
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => setState(() => showTable = !showTable),
              icon: Icon(showTable ? Icons.visibility_off : Icons.visibility),
              label: const Text('かけざん はやみひょう'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade100)),
            if (showTable) _buildMultiTable(),
          ],
        ])))),
    );
  }

  Widget _buildNormalUI(String op) => Column(children: [
    const SizedBox(height: 30),
    story.isNotEmpty
        ? Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(elevation: 4, child: Padding(padding: const EdgeInsets.all(20),
                child: Text(story, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center))))
        : Text('$n1 $op $n2 ＝ ?', style: const TextStyle(fontSize: 55, fontWeight: FontWeight.bold)),
    const SizedBox(height: 30),
    widget.isSelect ? _buildChoiceGrid() : Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: TextField(controller: _ansCtrl, keyboardType: TextInputType.number,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 38),
            onSubmitted: (v) => _checkAnswer(int.tryParse(v) == target))),
      const SizedBox(height: 12),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: () => _checkAnswer(int.tryParse(_ansCtrl.text) == target),
        child: const Text('こたえあわせ！', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    ]),
    const SizedBox(height: 20),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (hintLevel == 0)
        TextButton.icon(
          onPressed: () => setState(() => hintLevel = 1),
          icon: const Icon(Icons.lightbulb_outline),
          label: const Text('ヒント①'),
        ),
      if (hintLevel == 1) ...[
        TextButton.icon(
          onPressed: () => setState(() => hintLevel = 0),
          icon: const Icon(Icons.lightbulb, color: Colors.amber),
          label: const Text('ヒントをかくす'),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => setState(() => hintLevel = 2),
          icon: const Icon(Icons.lightbulb, color: Colors.orange),
          label: const Text('ヒント②'),
        ),
      ],
      if (hintLevel == 2)
        TextButton.icon(
          onPressed: () => setState(() => hintLevel = 0),
          icon: const Icon(Icons.lightbulb, color: Colors.orange),
          label: const Text('ヒントをかくす'),
        ),
    ]),
    if (hintLevel > 0) _buildHintArea(op, hintLevel),
  ]);

  Widget _buildChoiceGrid() => GridView.count(
    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2, mainAxisSpacing: 15, crossAxisSpacing: 15,
    padding: const EdgeInsets.symmetric(horizontal: 40), childAspectRatio: 1.8,
    children: choices.map((c) => ElevatedButton(
      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      onPressed: () => _checkAnswer(c == target),
      child: Text('$c', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)))).toList());

  // ── おかいもの問題UI ────────────────────────────────────────────
  Widget _buildShoppingUI() {
    return Column(children: [
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Card(
          elevation: 4, color: Colors.pink.shade50,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              const Text('🛒 おみせやさん', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              // 商品2つを価格付きで表示
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _shopItem(shopItemA, shopPriceA),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('＋', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                ),
                _shopItem(shopItemB, shopPriceB),
              ]),
              const SizedBox(height: 16),
              // 問い
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.pink.shade200),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    shopIsChange
                        ? '💰 ${shopPaid}えん だしたら\nおつりは なんえん？'
                        : 'ぜんぶで なんえん？',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.6),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 24),
      widget.isSelect
          ? _buildChoiceGrid()
          : Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: TextField(
                  controller: _ansCtrl, keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 36),
                  decoration: const InputDecoration(suffixText: 'えん'),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () => _checkAnswer(int.tryParse(_ansCtrl.text) == target),
                child: const Text('こたえあわせ！', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ]),
      const SizedBox(height: 20),
    ]);
  }

  Widget _shopItem(String name, int price) {
    return Column(children: [
      Text(name, style: const TextStyle(fontSize: 28)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.pink.shade300),
        ),
        child: Text('${price}えん',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.pink.shade700)),
      ),
    ]);
  }

  // ── 数の大小比較UI ──────────────────────────────────────────────
  Widget _buildCompareUI() {
    return Column(children: [
      const SizedBox(height: 40),
      // 常に「A ？ B」の順で固定表示
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _cmpBox('$cmpA', Colors.cyan.shade100, Colors.cyan.shade300),
        const SizedBox(width: 12),
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: Colors.grey.shade100, borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Center(child: Text('？', style: TextStyle(fontSize: 26, color: Colors.grey))),
        ),
        const SizedBox(width: 12),
        _cmpBox('$cmpB', Colors.orange.shade100, Colors.orange.shade300),
      ]),
      const SizedBox(height: 12),
      // A と B の説明ラベル
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(width: 80, child: Center(child: Text('ひだり', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)))),
        const SizedBox(width: 76),
        SizedBox(width: 80, child: Center(child: Text('みぎ', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)))),
      ]),
      const SizedBox(height: 32),
      // 選択肢：「ひだり ＞ みぎ」「ひだり ＜ みぎ」の形で統一
      Column(children: cmpChoices.map((sign) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: sign == '＞' ? Colors.red.shade50 : Colors.blue.shade50,
                foregroundColor: Colors.black87,
                side: BorderSide(color: sign == '＞' ? Colors.red.shade300 : Colors.blue.shade300, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              onPressed: () => _checkAnswer(sign == correctSign),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  children: [
                    TextSpan(text: '$cmpA ', style: TextStyle(color: Colors.cyan.shade700)),
                    TextSpan(text: sign, style: const TextStyle(fontSize: 28, color: Colors.black)),
                    TextSpan(text: ' $cmpB', style: TextStyle(color: Colors.orange.shade700)),
                  ],
                ),
              ),
            ),
          ),
        )
      ).toList()),
      const SizedBox(height: 30),
    ]);
  }

  Widget _cmpBox(String val, Color bg, Color border) => Container(
    width: 80, height: 80,
    decoration: BoxDecoration(
      color: bg, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: border, width: 2),
    ),
    child: Center(child: Text(val,
        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold))),
  );

  // ── 虫食い算強化UI ──────────────────────────────────────────────
  Widget _buildFillBothUI() {
    // □の位置に応じて式を組み立て
    String leftStr  = fillIsLeft  ? '□' : '$fillA';
    String rightStr = !fillIsLeft ? '□' : '$fillB';
    int result;
    switch (fillOp) {
      case '＋': result = fillA + fillB; break;
      case '－': result = fillA - fillB; break;
      case '×': result = fillA * fillB; break;
      default:   result = (fillA / fillB).round();
    }

    return Column(children: [
      const SizedBox(height: 30),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.lime.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.lime.shade400, width: 2),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _fillBox(leftStr),
          Text(' $fillOp ', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          _fillBox(rightStr),
          const Text(' ＝ ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          Text('$result', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.red)),
        ]),
      ),
      const SizedBox(height: 10),
      Text('□ に はいる かずは？',
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
      const SizedBox(height: 24),
      widget.isSelect
          ? GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
              padding: const EdgeInsets.symmetric(horizontal: 40), childAspectRatio: 1.8,
              children: fillChoices.map((c) => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lime.shade100,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () => _checkAnswer(c == target),
                child: Text('$c', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              )).toList())
          : Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: TextField(
                  controller: _ansCtrl, keyboardType: TextInputType.number,
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 38),
                  onSubmitted: (v) => _checkAnswer(int.tryParse(v) == target),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lime.shade600, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () => _checkAnswer(int.tryParse(_ansCtrl.text) == target),
                child: const Text('こたえあわせ！', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ]),
      const SizedBox(height: 20),
    ]);
  }

  Widget _fillBox(String val) {
    final isBlank = val == '□';
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        color: isBlank ? Colors.orange.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBlank ? Colors.orange.shade400 : Colors.grey.shade300,
          width: isBlank ? 2.5 : 1,
        ),
      ),
      child: Center(child: Text(val,
          style: TextStyle(
            fontSize: 28, fontWeight: FontWeight.bold,
            color: isBlank ? Colors.orange.shade700 : Colors.black87,
          ))),
    );
  }

  // ── 挑戦状UI ────────────────────────────────────────────────────
  Widget _buildChallengeUI() {
    if (_challengeList.isEmpty || _challengeIdx >= _challengeList.length) {
      return const SizedBox();
    }
    final item = _challengeList[_challengeIdx];
    final from    = item['from']    as String? ?? 'パパ・ママ';
    final message = item['message'] as String? ?? '';
    final question = item['question'] as String? ?? '';
    final answer   = item['answer']   as int;

    // 選択肢生成（targetにanswerをセット済み）
    final r = Random();
    if (choices.length != 4 || !choices.contains(answer)) {
      final s = <int>{answer};
      while (s.length < 4) {
        final d = answer + r.nextInt(10) - 4;
        if (d >= 0) s.add(d);
      }
      choices = s.toList()..shuffle();
    }

    return Column(children: [
      const SizedBox(height: 16),
      // 差出人カード
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.deepOrange.shade100, Colors.orange.shade50]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.deepOrange.shade200),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('📝 ', style: TextStyle(fontSize: 18)),
              Text('$from からの ちょうせんじょう！',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                      color: Colors.deepOrange.shade700)),
              const Spacer(),
              Text('${_challengeIdx + 1} / ${_challengeList.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ]),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('💬 $message',
                    style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, height: 1.5)),
              ),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 20),
      // 問題
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(question,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.7),
                textAlign: TextAlign.center,
                softWrap: true,
                overflow: TextOverflow.visible,),
          ),
        ),
      ),
      const SizedBox(height: 24),
      widget.isSelect
          ? _buildChoiceGrid()
          : Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: TextField(
                  controller: _ansCtrl, keyboardType: TextInputType.number,
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 38),
                  onSubmitted: (v) => _checkAnswer(int.tryParse(v) == answer),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () => _checkAnswer(int.tryParse(_ansCtrl.text) == answer),
                child: const Text('こたえあわせ！', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ]),
      const SizedBox(height: 20),
    ]);
  }

  // ── 10のまとまりUI ─────────────────────────────────────────────
  Widget _buildTensUI() {
    final question = tensAskTotal
        ? '10の まとまりが $tensBlocks こ、バラが $tensOnes こ。\nぜんぶで いくつ？'
        : '${tensBlocks * 10 + tensOnes} は、10の まとまりが いくつ と バラが $tensOnes こ？';

    // まとまりをブロックで視覚表示
    return Column(children: [
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          color: Colors.teal.shade50,
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Text(question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, height: 1.7)),
              const SizedBox(height: 16),
              // ブロック視覚表示
              Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
                // 10のまとまりブロック（黄色）
                ...List.generate(tensBlocks, (i) => Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade400,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade700),
                  ),
                  child: const Center(child: Text('10',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))),
                )),
                // バラの点（水色）
                ...List.generate(tensOnes, (i) => Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: Colors.cyan.shade300,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.cyan.shade600),
                  ),
                  child: Center(child: Text('1',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.cyan.shade900))),
                )),
              ]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _tensLegend(Colors.amber.shade400, '10のまとまり ×$tensBlocks'),
                const SizedBox(width: 12),
                if (tensOnes > 0) _tensLegend(Colors.cyan.shade300, 'バラ ×$tensOnes'),
              ]),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 20),
      GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
        padding: const EdgeInsets.symmetric(horizontal: 40), childAspectRatio: 1.8,
        children: tensChoices.map((c) => ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade100, foregroundColor: Colors.black87,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: () => _checkAnswer(c == target),
          child: Text('$c', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        )).toList()),
      const SizedBox(height: 16),
    ]);
  }

  Widget _tensLegend(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
  ]);

  Widget _buildPuzzleUI() {
    // パズルルール説明文
    String ruleText;
    if (widget.pLv == 3) {
      ruleText = '3つの □ に すうじを いれて\nあわせると あかいかずに なるように しよう！';
    } else if (pOp == '÷') {
      ruleText = '□ $pOp □ ＝ あかいかず に なるように\n2つの □ に すうじを いれよう！\n（わりきれる かずを さがそう）';
    } else {
      ruleText = '□ $pOp □ ＝ あかいかず に なるように\n2つの □ に すうじを いれよう！';
    }

    // 10. ÷パズル × 選択モードのとき：式を見せて答え（商）を4択で選ぶ
    if (pOp == '÷' && widget.isSelect) {
      return Column(children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            color: Colors.yellow.shade100, elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('📝 ', style: TextStyle(fontSize: 20)),
                Expanded(child: Text('こたえを えらんでね！',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, height: 1.6))),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('$n1 $pOp $n2 ＝ ?',
            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildChoiceGrid(),
        const SizedBox(height: 16),
      ]);
    }

    return Column(children: [
    const SizedBox(height: 16),
    // ルール説明カード
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        color: Colors.yellow.shade100,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📝 ', style: TextStyle(fontSize: 20)),
            Expanded(child: Text(ruleText,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, height: 1.6))),
          ]),
        ),
      ),
    ),
    const SizedBox(height: 16),
    Text(target.toString(), style: const TextStyle(fontSize: 60, color: Colors.red, fontWeight: FontWeight.bold)),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _puzzleSlot(0), Text(pOp, style: const TextStyle(fontSize: 28)), _puzzleSlot(1),
      if (widget.pLv == 3) ...[const Text(' ＋ ', style: TextStyle(fontSize: 28)), _puzzleSlot(2)],
    ]),
    const SizedBox(height: 25),
    Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
      children: List.generate(21, (i) => ElevatedButton(
        onPressed: () {
          setState(() { final idx = slots.indexOf(null); if (idx != -1) slots[idx] = i; });
          if (!slots.contains(null)) {
            double res = 0;
            if (pOp == '＋')      res = (slots[0]! + slots[1]!).toDouble();
            else if (pOp == '－') res = (slots[0]! - slots[1]!).toDouble();
            else if (pOp == '×') res = (slots[0]! * slots[1]!).toDouble();
            else if (pOp == '÷') {
              if (slots[1] == 0) { setState(() => slots = List.filled(2, null)); return; }
              res = slots[0]! / slots[1]!;
            }
            if (widget.pLv == 3) res = (slots[0]! + slots[1]! + slots[2]!).toDouble();
            _checkAnswer(res == target.toDouble());
          }
        },
        child: Text('$i')))),
    TextButton(onPressed: () => setState(() => slots = List.filled(widget.pLv == 3 ? 3 : 2, null)),
        child: const Text('やりなおす')),
    ]);
  }

  Widget _puzzleSlot(int i) => Container(
    width: 50, height: 50, margin: const EdgeInsets.all(5),
    decoration: BoxDecoration(border: Border.all(color: Colors.orange), borderRadius: BorderRadius.circular(10)),
    child: Center(child: Text(slots[i]?.toString() ?? '?', style: const TextStyle(fontSize: 24))));

  Widget _buildMultiTable() => Card(
    elevation: 0, color: Colors.white, margin: const EdgeInsets.all(15),
    child: Padding(padding: const EdgeInsets.all(10),
      child: Table(border: TableBorder.all(color: Colors.grey.shade200, width: 0.5),
        children: List.generate(10, (r) => TableRow(children: List.generate(10, (c) {
          if (r == 0 && c == 0) return const Center(child: Text('×', style: TextStyle(fontSize: 14, color: Colors.grey)));
          if (r == 0 || c == 0) return Container(height: 35, color: Colors.orange.shade50,
            child: Center(child: Text('${r == 0 ? c : r}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))));
          final active = (r == n1 && c == n2);
          return Container(height: 35, color: active ? Colors.purple.shade200 : Colors.white,
            child: Center(child: Text('${r * c}', style: TextStyle(fontSize: 13, color: Colors.grey.shade800))));
        }))))));

  // 絵文字が多すぎる場合は上限で切り、残り数を表示
  Widget _emojiWrap(String em, int count, {double size = 24}) {
    const int cap = 20;
    if (count <= cap) {
      return Wrap(alignment: WrapAlignment.center,
          children: List.generate(count, (_) => Text(em, style: TextStyle(fontSize: size))));
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Wrap(children: List.generate(cap, (_) => Text(em, style: TextStyle(fontSize: size)))),
      Text(' … ×$count', style: TextStyle(fontSize: size * 0.7, color: Colors.grey)),
    ]);
  }

  Widget _buildHintArea(String op, int level) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: level == 1 ? Colors.amber.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: level == 1 ? Colors.amber.shade200 : Colors.orange.shade300),
      ),
      child: Column(children: [
        Text(level == 1 ? '💡 ヒント①' : '💡💡 ヒント②',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                color: level == 1 ? Colors.amber.shade800 : Colors.orange.shade800)),
        const SizedBox(height: 10),
        if (op == '＋') _hintPlus(level),
        if (op == '－') _hintMinus(level),
        if (op == '×') _hintMulti(level),
        if (op == '÷') _hintDiv(level),
      ]),
    );
  }

  // ── たしざん ──
  Widget _hintPlus(int level) {
    if (level == 1) {
      return Text('$n1 と $n2 を あわせると いくつ？\nひとつずつ かぞえて みよう！',
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.6));
    }
    return Column(children: [
      _emojiWrap(emoji, n1, size: 26),
      const Padding(padding: EdgeInsets.symmetric(vertical: 4),
          child: Text('➕', style: TextStyle(fontSize: 22))),
      _emojiWrap(emoji, n2, size: 26),
      const SizedBox(height: 6),
      Text('ぜんぶで $target こ！', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
    ]);
  }

  // ── ひきざん ──
  Widget _hintMinus(int level) {
    if (level == 1) {
      return Text('$n1 から $n2 を とると いくつ のこる？\n$n1 から ひとつずつ へらして みよう！',
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.6));
    }
    return Column(children: [
      _emojiWrap(emoji, target, size: 26),
      const SizedBox(height: 4),
      Text('🍴 の $n2 こ を とると…', style: const TextStyle(fontSize: 14, color: Colors.grey)),
      const SizedBox(height: 4),
      _emojiWrap(emoji, target, size: 26),
      const SizedBox(height: 6),
      Text('$target こ のこる！', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
    ]);
  }

  // ── かけざん ──
  Widget _hintMulti(int level) {
    if (level == 1) {
      return Text('$n2 こずつの グループが $n1 つ あるよ！\nグループを たしていくと いくつ？',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, height: 1.6));
    }
    return Column(children: [
      Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 8,
        children: List.generate(n1, (i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.purple.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.purple.shade50,
          ),
          child: Column(children: [
            Text('グループ ${i + 1}', style: TextStyle(fontSize: 10, color: Colors.purple.shade700)),
            Wrap(children: List.generate(n2, (_) => const Text('🍬', style: TextStyle(fontSize: 22)))),
          ]),
        ))),
      const SizedBox(height: 8),
      Text('$n2 × $n1 ＝ $target', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
    ]);
  }

  // ── わりざん ──
  Widget _hintDiv(int level) {
    if (level == 1) {
      return Text('$n1 こを $n2 にんで おなじかずずつ わけると\nひとり なんこ もらえる？',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, height: 1.6));
    }
    return Column(children: [
      Text('$n1 こを $n2 にんに わけると…', style: const TextStyle(fontSize: 14, color: Colors.grey)),
      const SizedBox(height: 8),
      Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8,
        children: List.generate(n2, (i) => Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.teal.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.teal.shade50,
          ),
          child: Column(children: [
            Text('${i + 1}にんめ', style: TextStyle(fontSize: 10, color: Colors.teal.shade700)),
            Wrap(children: List.generate(target, (_) => Text(emoji, style: const TextStyle(fontSize: 20)))),
          ]),
        ))),
      const SizedBox(height: 8),
      Text('ひとり $target こ！', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
    ]);
  }
}

// ── まちがい履歴ページ ────────────────────────────────────────────────
class HistoryPage extends StatefulWidget {
  final List<Map<String, dynamic>> history;
  const HistoryPage({super.key, required this.history});

  @override State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    // miss降順でソートしてコピー
    _items = List.from(widget.history)
      ..sort((a, b) => ((b['miss'] as int?) ?? 1).compareTo((a['miss'] as int?) ?? 1));
  }

  String _opStr(MathMode m) {
    if (m.isPlus)  return '＋';
    if (m.isMinus) return '－';
    if (m.isMulti) return '×';
    if (m == MathMode.shopping) return '💴';
    if (m == MathMode.compare)  return '？';
    return '÷';
  }

  Future<void> _dismiss(Map<String, dynamic> q) async {
    final mode = MathMode.fromString(q['m'] as String);
    await HistoryManager.dismiss(mode, q['n1'] as int, q['n2'] as int);
    setState(() => _items.remove(q));
  }

  @override
  Widget build(BuildContext context) {
    // モード別グループ
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final q in _items) {
      final m = q['m'] as String? ?? '';
      grouped.putIfAbsent(m, () => []).add(q);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('間違い 履歴'),
        backgroundColor: Colors.blueGrey.shade200,
        centerTitle: true,
      ),
      body: _items.isEmpty
          ? const Center(child: Text('全て確認済みです 🎉',
              style: TextStyle(fontSize: 16, color: Colors.grey)))
          : Container(
              color: Colors.blueGrey.shade50,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 凡例
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Wrap(spacing: 12, runSpacing: 6, children: [
                          _legend(Colors.red.shade100, Colors.red.shade300, '🔴 3回以上'),
                          _legend(Colors.orange.shade50, Colors.orange.shade200, '通常'),
                          const Text('✅ をタップすると 確認済みにできます',
                              style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ]),
                      ),
                      // グループ別に表示
                      ...grouped.entries.map((e) {
                        final mode     = MathMode.fromString(e.key);
                        final problems = e.value;
                        final modeMiss = problems.fold<int>(0, (s, q) => s + ((q['miss'] as int?) ?? 1));
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // グループヘッダー
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                              child: Row(children: [
                                Text(mode.label,
                                    style: const TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                const SizedBox(width: 8),
                                Text('${problems.length}問・$modeMiss回',
                                    style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400)),
                              ]),
                            ),
                            // 問題カード一覧
                            ...problems.map((q) {
                              final n1   = q['n1'] as int;
                              final n2   = q['n2'] as int;
                              final t    = q['t']  as int;
                              final miss = (q['miss'] as int?) ?? 1;
                              final qMode = MathMode.fromString(q['m'] as String);
                              final op   = _opStr(qMode);
                              final isHot = miss >= 3;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isHot ? Colors.red.shade50 : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isHot ? Colors.red.shade300 : Colors.orange.shade200,
                                    width: isHot ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(children: [
                                  // 式
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(
                                          qMode == MathMode.shopping
                                              ? ((q['isChange'] as int?) == 1
                                                  ? '${q['itemA'] ?? '?'} + ${q['itemB'] ?? '?'}  ${q['paid'] ?? '?'}えんだして おつり？'
                                                  : '${q['itemA'] ?? '?'} + ${q['itemB'] ?? '?'}  ぜんぶで なんえん？')
                                              : qMode == MathMode.compare
                                                  ? '$n1 ？ $n2'
                                                  : '$n1 $op $n2 ＝ ?',
                                          style: TextStyle(
                                              fontSize: qMode == MathMode.shopping ? 13 : 18,
                                              fontWeight: FontWeight.bold,
                                              color: isHot ? Colors.red.shade700 : Colors.black87)),
                                      const SizedBox(height: 2),
                                      Text(
                                          qMode == MathMode.compare
                                              ? '答え: $n1 ${n1 > n2 ? '＞' : '＜'} $n2'
                                              : '答え: $t',
                                          style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                                    ]),
                                  ),
                                  // 間違い回数バッジ
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isHot ? Colors.red.shade400 : Colors.blueGrey.shade100,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text('$miss回',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isHot ? Colors.white : Colors.blueGrey.shade700)),
                                  ),
                                  if (isHot) const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Text('🔴', style: TextStyle(fontSize: 14)),
                                  ),
                                  const SizedBox(width: 8),
                                  // 確認済みボタン
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                    tooltip: '確認済みにする',
                                    onPressed: () => _dismiss(q),
                                  ),
                                ]),
                              );
                            }),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _legend(Color bg, Color border, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10)),
    );
  }
}