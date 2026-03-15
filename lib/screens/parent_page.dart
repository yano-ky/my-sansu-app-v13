import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/math_mode.dart';
import '../models/managers.dart';
import '../models/badge_manager.dart';
import 'history_page.dart';
import 'badge_screen.dart';
import '../widgets/weekly_report_section.dart';
import '../widgets/calendar_section.dart';
import '../widgets/stats_chart.dart';
import '../widgets/challenge_editor_section.dart';

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
    'plus','minus','multi','div','story','puzzle','shopping','compare','fillBoth','tens',
    'clock','shape',
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
                _ParentSection(title: '📅 がくしゅう カレンダー',    child: _buildCalendar()),
                _ParentSection(title: '📊 週間 レポート',             child: _buildWeeklyReport()),
                _ParentSection(title: '📊 正解率 グラフ',             child: _buildStatsChart()),
                _ParentSection(title: '📋 間違い 履歴',               child: _buildWeakList()),
                _ParentSection(title: '👁️ メニューの 表示・ならびかえ', child: _buildVisibilitySettings()),
                _ParentSection(title: '📝 ちょうせんじょう を つくる', child: _buildChallengeEditor()),
                _ParentSection(title: '⚙️ 問題 設定',                 child: _buildSettings()),
                const SizedBox(height: 8),
                _buildResetButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 週間レポート ──────────────────────────────────────────────────

  Widget _buildWeeklyReport() => WeeklyReportSection(
      calendarData: calendarData, stats: stats);

    // ── カレンダー ────────────────────────────────────────────────────

  Widget _buildCalendar() => CalendarSection(calendarData: calendarData);

    // ── 正解率グラフ ──────────────────────────────────────────────────

  Widget _buildStatsChart() => StatsChart(stats: stats);

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
      'clock':    '🕐 とけい',        'shape':    '🔷 ずけい',
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

  Widget _buildChallengeEditor() => const ChallengeEditorSection();

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
          content: const Text('正解率・にがてリスト・バッジが 全て消えます。'),
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
        await BadgeManager.clearAll();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('wrongList');
        _load();
      }
    },
  );
}

// ── 保護者メニュー用フリップダウンセクション ─────────────────────────

class _ParentSection extends StatefulWidget {
  final String title;
  final Widget child;
  const _ParentSection({required this.title, required this.child});

  @override
  State<_ParentSection> createState() => _ParentSectionState();
}

class _ParentSectionState extends State<_ParentSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        // ヘッダー
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Expanded(
                child: Text(widget.title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey)),
              ),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.blueGrey),
            ]),
          ),
        ),
        // 展開時コンテンツ
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: widget.child,
          ),
      ]),
    );
  }
}