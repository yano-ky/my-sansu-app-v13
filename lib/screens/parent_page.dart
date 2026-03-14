import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/math_mode.dart';
import '../models/managers.dart';
import '../models/badge_manager.dart';
import 'history_page.dart';
import 'badge_screen.dart';

class ParentPage extends StatefulWidget {
  const ParentPage({super.key});
  @override State<ParentPage> createState() => _ParentPageState();
}

class _ParentPageState extends State<ParentPage> {
  double maxNum = 10, goal = 10;
  bool isSelect = true, timeAttack = false, showCharacter = true;
  Map<MathMode, Map<String, int>> stats = {};
  List<dynamic> wrongList = [];
  List<Map<String, dynamic>> history = [];
  Set<String> hiddenModes = {};
  List<String> menuOrder = const [
    'plus','minus','multi','div','story','puzzle','shopping','compare','fillBoth','tens'
  ];
  Map<String, int> calendarData = {};

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final s    = await StatsManager.loadAll();
    final hist = await HistoryManager.loadActive();
    final cal  = await CalendarManager.loadRecent();
    List<dynamic> wl = [];
    try {
      final saved = prefs.getString('wrongList');
      if (saved != null) wl = json.decode(saved);
    } catch (_) {}
    setState(() {
      maxNum       = prefs.getDouble('maxNum')   ?? 10;
      goal         = prefs.getDouble('goal')     ?? 10;
      isSelect      = prefs.getBool('isSelect')      ?? true;
      timeAttack    = prefs.getBool('timeAttack')    ?? false;
      showCharacter = prefs.getBool('showCharacter') ?? true;
      stats        = s;
      wrongList    = wl;
      history      = hist;
      hiddenModes  = (prefs.getStringList('hiddenModes') ?? []).toSet();
      final savedOrder = prefs.getStringList('menuOrder');
      if (savedOrder != null && savedOrder.length == menuOrder.length) {
        menuOrder = savedOrder;
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
    await prefs.setBool('showCharacter', showCharacter);
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
                _sectionTitle('📊 週間 レポート'),
                _buildWeeklyReport(),
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
    child: Text(text,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
  );

  // ── 週間レポート ──────────────────────────────────────────────────

  Widget _buildWeeklyReport() {
    final now = DateTime.now();
    int weekTotal = 0, weekDays = 0;
    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      final k = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      final v = calendarData[k] ?? 0;
      if (v > 0) { weekTotal += v; weekDays++; }
    }
    final prevTotal = (() {
      int t = 0;
      for (int i = 7; i < 14; i++) {
        final d = now.subtract(Duration(days: i));
        final k = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
        t += calendarData[k] ?? 0;
      }
      return t;
    })();
    final diff = weekTotal - prevTotal;
    final diffStr = diff > 0 ? '▲$diff もん' : diff < 0 ? '▼${-diff} もん' : '±0';
    final diffColor = diff > 0 ? Colors.green : diff < 0 ? Colors.red : Colors.grey;

    // 今週の正解率（全statsから今週分を概算）
    final totalStat = stats.values.fold(0, (s, m) => s + (m['total'] ?? 0));
    final correctStat = stats.values.fold(0, (s, m) => s + (m['correct'] ?? 0));
    final overallPct = totalStat == 0 ? 0 : (correctStat * 100 / totalStat).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: _weekStat('今週の問題数', '$weekTotal もん', Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _weekStat('れんしゅう日数', '$weekDays / 7 日', Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _weekStat('全体正解率', '$overallPct %', Colors.green)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(children: [
              const Text('先週比', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 8),
              Text(diffStr,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: diffColor)),
              const Spacer(),
              Text('先週: $prevTotal もん',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ),
          const SizedBox(height: 12),
          // 今週7日バーグラフ
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final d = now.subtract(Duration(days: 6 - i));
              final k = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
              final v = calendarData[k] ?? 0;
              final maxV = List.generate(7, (j) {
                final dd = now.subtract(Duration(days: 6-j));
                final kk = '${dd.year}-${dd.month.toString().padLeft(2,'0')}-${dd.day.toString().padLeft(2,'0')}';
                return calendarData[kk] ?? 0;
              }).fold(1, (a, b) => a > b ? a : b);
              final h = v == 0 ? 4.0 : (v / maxV * 60).clamp(8.0, 60.0);
              final isToday = i == 6;
              final weekDay = ['月','火','水','木','金','土','日'][d.weekday - 1];
              return Expanded(child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (v > 0) Text('$v', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Container(
                    height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isToday ? Colors.orange : Colors.orange.shade200,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(weekDay,
                      style: TextStyle(
                          fontSize: 10,
                          color: isToday ? Colors.orange : Colors.grey)),
                ],
              ));
            }),
          ),
          const SizedBox(height: 12),
          // バッジリンク
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
              side: BorderSide(color: Colors.amber.shade300),
              foregroundColor: Colors.brown,
              backgroundColor: Colors.amber.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Text('🏅', style: TextStyle(fontSize: 16)),
            label: const Text('バッジ コレクションを みる',
                style: TextStyle(fontSize: 13)),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BadgeScreen())),
          ),
        ]),
      ),
    );
  }

  Widget _weekStat(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(children: [
      Text(value, style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center),
    ]),
  );

  // ── カレンダー ────────────────────────────────────────────────────

  Widget _buildCalendar() {
    final entries  = calendarData.entries.toList();
    final maxCount = entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);
    final today    = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final totalDays  = entries.where((e) => e.value > 0).length;
    final todayCount = calendarData[todayKey] ?? 0;
    const weekLabels = ['月', '火', '水', '木', '金', '土', '日'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _calBadge('きょう ${todayCount}もん',
                todayCount > 0 ? Colors.orange.shade50 : Colors.grey.shade50,
                todayCount > 0 ? Colors.orange.shade200 : Colors.grey.shade200,
                todayCount > 0 ? Colors.orange.shade700 : Colors.grey),
            const SizedBox(width: 10),
            _calBadge('35日で $totalDays 日れんしゅう',
                Colors.blue.shade50, Colors.blue.shade100, Colors.blue.shade700,
                fontSize: 12),
          ]),
          const SizedBox(height: 12),
          Row(children: weekLabels.map((w) => Expanded(
            child: Center(child: Text(w, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold,
              color: w == '日' ? Colors.red.shade400
                   : w == '土' ? Colors.blue.shade400
                   : Colors.grey.shade600,
            ))),
          )).toList()),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisSpacing: 3, crossAxisSpacing: 3, childAspectRatio: 1.1),
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final entry     = entries[i];
              final count     = entry.value;
              final isToday   = entry.key == todayKey;
              final intensity = maxCount == 0 ? 0.0 : count / maxCount;
              final cellColor = count == 0          ? Colors.grey.shade100
                              : intensity < 0.33    ? Colors.orange.shade100
                              : intensity < 0.66    ? Colors.orange.shade300
                              :                       Colors.orange.shade500;
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
                    Text('$dayNum', style: TextStyle(
                      fontSize: 10,
                      color: count > 0
                          ? (intensity >= 0.66 ? Colors.white : Colors.orange.shade900)
                          : Colors.grey.shade400,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    )),
                    if (count > 0)
                      Text('$count', style: TextStyle(
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
            ...[Colors.grey.shade100, Colors.orange.shade100,
                Colors.orange.shade300, Colors.orange.shade500]
                .map((c) => Container(
                  width: 14, height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                      color: c, borderRadius: BorderRadius.circular(2)))),
            const Text(' おおい', style: TextStyle(fontSize: 10, color: Colors.grey)),
            const Spacer(),
            Container(width: 12, height: 12,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepOrange, width: 2),
                    borderRadius: BorderRadius.circular(2))),
            const Text(' きょう', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
        ]),
      ),
    );
  }

  Widget _calBadge(String text, Color bg, Color border, Color textColor,
      {double fontSize = 13}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: textColor)),
      );

  // ── 正解率グラフ ──────────────────────────────────────────────────

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
          child: Center(child: Text('まだ データが ありません',
              style: TextStyle(color: Colors.grey)))));
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
            final barColor = pct >= 80 ? Colors.green
                           : pct >= 50 ? Colors.orange
                           :             Colors.red;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                SizedBox(width: 52,
                    child: Text(labels[i], style: const TextStyle(fontSize: 12))),
                const SizedBox(width: 4),
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: rate, minHeight: 20,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                )),
                const SizedBox(width: 8),
                SizedBox(width: 80,
                  child: Text(total == 0 ? '－' : '$pct% ($correct/$total)',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700))),
              ]),
            );
          }),
        ),
      ),
    );
  }

  // ── 間違い履歴サマリー ────────────────────────────────────────────

  Widget _buildWeakList() {
    if (history.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16),
          child: Center(child: Text('まだ 間違いがありません 🎉',
              style: TextStyle(color: Colors.grey)))));
    }
    final totalMiss = history.fold<int>(0, (s, q) => s + ((q['miss'] as int?) ?? 1));
    final hotCount  = history.where((q) => ((q['miss'] as int?) ?? 1) >= 3).length;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => HistoryPage(history: history)));
          _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _badge('${history.length} もん きろく',
                    Colors.blueGrey.shade50, Colors.blueGrey.shade200),
                const SizedBox(width: 8),
                _badge('のべ $totalMiss かいまちがい',
                    Colors.orange.shade50, Colors.orange.shade200,
                    textColor: Colors.orange.shade700),
              ]),
              if (hotCount > 0) ...[
                const SizedBox(height: 6),
                _badge('🔴 $hotCount もん が3かい以上まちがい',
                    Colors.red.shade50, Colors.red.shade200,
                    textColor: Colors.red),
              ],
              const SizedBox(height: 6),
              const Text('▶ くわしくみる',
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
            ])),
            const Icon(Icons.chevron_right, color: Colors.blueGrey),
          ]),
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color border,
      {Color? textColor, double fontSize = 13}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: textColor)),
      );

  // ── 表示・ならびかえ ──────────────────────────────────────────────

  Widget _buildVisibilitySettings() {
    const labelMap = {
      'plus':     '➕ たしざん',      'minus':    '➖ ひきざん',
      'multi':    '✖ かけざん',       'div':      '➗ わりざん',
      'story':    '📖 ぶんしょう',    'puzzle':   '🧩 パズル',
      'shopping': '💴 おかいもの',    'compare':  '🔢 かずの おおきさ',
      'fillBoth': '🧮 むしくいざん',  'tens':     '🔟 10の まとまり',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              final label     = labelMap[key] ?? key;
              final isVisible = !hiddenModes.contains(key);
              return Material(
                key: ValueKey(key),
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.only(left: 12, right: 4),
                  title: Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(isVisible ? 'メニューに表示' : '隠している',
                      style: TextStyle(
                          fontSize: 11,
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
        ]),
      ),
    );
  }

  // ── 設定 ─────────────────────────────────────────────────────────

  Widget _buildSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: StatefulBuilder(builder: (context, setS) {
          final v = maxNum.round();
          final String levelName;
          final Color  levelColor;
          if (v <= 10)      { levelName = '1桁';          levelColor = Colors.blue; }
          else if (v <= 20) { levelName = '少し2桁';    levelColor = Colors.green; }
          else if (v <= 50) { levelName = '2桁・普通';  levelColor = Colors.orange; }
          else              { levelName = '2桁・難しい'; levelColor = Colors.red; }

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🔢 難しさ', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Row(children: [
              Text('$v まで',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: levelColor)),
              const SizedBox(width: 8),
              Text('($levelName)', style: TextStyle(fontSize: 12, color: levelColor)),
            ]),
            Slider(
              value: maxNum, min: 10, max: 100, divisions: 9,
              activeColor: levelColor,
              onChanged: (val) { setS(() => maxNum = val); setState(() {}); },
              onChangeEnd: (_) => _save(),
            ),
            const Divider(),
            const Text('🏁 問題数', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('${goal.toInt()} 問',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            Slider(
              value: goal, min: 5, max: 50, divisions: 9,
              onChanged: (val) { setS(() => goal = val); setState(() {}); },
              onChangeEnd: (_) => _save(),
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('⏱️ タイムアタック',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(timeAttack ? '30秒で何問解けるか挑戦！' : 'タイムアタックOFF',
                  style: const TextStyle(fontSize: 11)),
              value: timeAttack,
              onChanged: (v) { setS(() => timeAttack = v); setState(() {}); _save(); },
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('🐰 うさぎキャラクター',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(showCharacter ? 'ゲーム中にキャラクターを表示' : 'キャラクターを非表示',
                  style: const TextStyle(fontSize: 11)),
              value: showCharacter,
              onChanged: (v) { setS(() => showCharacter = v); setState(() {}); _save(); },
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('🔘 選ぶモード',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

  // ── 挑戦状エディター ─────────────────────────────────────────────

  Widget _buildChallengeEditor() {
    final fromCtrl = TextEditingController();
    final msgCtrl  = TextEditingController();
    final qCtrl    = TextEditingController();
    final ansCtrl  = TextEditingController();

    return StatefulBuilder(builder: (context, setS) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('登録済み ${list.length} 問',
                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                  const SizedBox(height: 6),
                  ...list.asMap().entries.map((e) {
                    final i = e.key; final item = e.value;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.deepOrange.shade100,
                        child: Text('${i + 1}',
                            style: const TextStyle(fontSize: 11)),
                      ),
                      title: Text(item['question'] as String? ?? '',
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          '答え: ${item["answer"]}  from: ${item["from"] ?? ""}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        onPressed: () async {
                          final newList = List<Map<String, dynamic>>.from(list)
                            ..removeAt(i);
                          await ChallengeManager.save(newList);
                          setS(() {});
                        },
                      ),
                    );
                  }),
                  const Divider(),
                ]);
              },
            ),
            const Text('＋ あたらしく つくる',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey)),
            const SizedBox(height: 10),
            TextField(controller: fromCtrl,
                decoration: const InputDecoration(
                    labelText: '差出人（例：パパ、ママ）',
                    border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 8),
            TextField(controller: msgCtrl,
                decoration: const InputDecoration(
                    labelText: 'ひとことメッセージ（任意）',
                    hintText: '例：がんばれ！パパより',
                    border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 8),
            TextField(controller: qCtrl, maxLines: 2,
                decoration: const InputDecoration(
                    labelText: '問題文',
                    hintText: '例：12＋34は？',
                    border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 8),
            TextField(controller: ansCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: '答え（数字）',
                    border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('ちょうせんじょうに 追加'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white),
                onPressed: () async {
                  final ans = int.tryParse(ansCtrl.text);
                  if (qCtrl.text.isEmpty || ans == null) return;
                  final list = await ChallengeManager.loadAll();
                  list.add({
                    'from':     fromCtrl.text.isEmpty ? 'パパ・ママ' : fromCtrl.text,
                    'message':  msgCtrl.text,
                    'question': qCtrl.text,
                    'answer':   ans,
                  });
                  await ChallengeManager.save(list);
                  fromCtrl.clear(); msgCtrl.clear();
                  qCtrl.clear(); ansCtrl.clear();
                  setS(() {});
                },
              ),
            ),
          ]),
        ),
      );
    });
  }

  // ── リセット ─────────────────────────────────────────────────────

  Widget _buildResetButton() => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
    icon: const Icon(Icons.delete_forever),
    label: const Text('記録を すべて リセット'),
    onPressed: () async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('リセットしますか？'),
          content: const Text('正解率・にがてリストが 全て消えます。'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('キャンセル')),
            TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('リセット',
                    style: TextStyle(color: Colors.red))),
          ],
        ),
      );
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
