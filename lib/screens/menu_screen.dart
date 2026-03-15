import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/math_mode.dart';
import '../models/managers.dart';
import '../models/badge_manager.dart';
import '../widgets/character_widget.dart';
import 'math_game_screen.dart';
import 'parent_page.dart';
import 'sub_menus.dart';
import 'badge_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  double maxNum = 10, goal = 10;
  bool isSelect = true;
  bool timeAttack = false;
  bool showCharacter = true;
  List<dynamic> wrongList = [];
  List<Map<String, dynamic>> challengeList = [];
  Set<String> hiddenModes = {};
  String _advice = '';
  MathMode? _weakMode;

  static const _defaultOrder = [
    'plus', 'minus', 'multi', 'div',
    'story', 'puzzle', 'shopping', 'compare', 'fillBoth', 'tens',
    'clock', 'shape',
  ];
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
    final stats = await StatsManager.loadAll();
    // 苦手分野（正解率が最も低いモード）
    MathMode? weak;
    double weakRate = 1.0;
    for (final e in stats.entries) {
      final t = e.value['total'] ?? 0;
      if (t < 3) continue;
      final r = (e.value['correct'] ?? 0) / t;
      if (r < weakRate) { weakRate = r; weak = e.key; }
    }
    setState(() {
      maxNum        = prefs.getDouble('maxNum')      ?? 10;
      goal          = prefs.getDouble('goal')        ?? 10;
      isSelect      = prefs.getBool('isSelect')      ?? true;
      timeAttack    = prefs.getBool('timeAttack')    ?? false;
      showCharacter = prefs.getBool('showCharacter') ?? true;
      wrongList     = parsed;
      challengeList = cl;
      hiddenModes   = (prefs.getStringList('hiddenModes') ?? []).toSet();
      final savedOrder = prefs.getStringList('menuOrder');
      if (savedOrder != null && savedOrder.length == _defaultOrder.length) {
        menuOrder = savedOrder;
      } else {
        menuOrder = List.from(_defaultOrder);
      }
      _advice   = AdviceManager.menuAdvice();
      _weakMode = weak;
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
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ParentPage()));
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
                // ── キャラ＋アドバイス ──
                if (showCharacter) ...[
                  Row(children: [
                    CharacterWidget(state: CharState.cheer, size: 72),
                    const SizedBox(width: 12),
                    Expanded(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(_advice,
                          style: const TextStyle(fontSize: 14, height: 1.5)),
                    )),
                  ]),
                  const SizedBox(height: 12),
                ],
                // ── 苦手おすすめ ──
                if (_weakMode != null) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => MathGame(
                              mode: _weakMode!, maxNum: maxNum.toInt(),
                              goal: goal.toInt(), isSelect: isSelect,
                              timeAttack: timeAttack)));
                      _loadSettings();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.yellow.shade400),
                      ),
                      child: Row(children: [
                        const Text('💡', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          'きょうは「${_weakMode!.label}」を れんしゅうしよう！',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        )),
                        const Icon(Icons.chevron_right, size: 18),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                // ── バッジボタン ──
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    side: BorderSide(color: Colors.amber.shade400),
                    backgroundColor: Colors.amber.shade50,
                    foregroundColor: Colors.brown,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Text('🏅', style: TextStyle(fontSize: 18)),
                  label: const Text('バッジ コレクション',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const BadgeScreen())),
                ),
                const SizedBox(height: 8),
                if (wrongList.isNotEmpty)
                  _menuCard('🔥 にがてを こくふく (${wrongList.length})',
                      Colors.red.shade100, MathMode.wrong),
                ...menuOrder
                    .where((k) => !hiddenModes.contains(k))
                    .map((k) => _menuCardByKey(k)),
                if (challengeList.isNotEmpty)
                  _menuCard(
                      '📝 ちょうせんじょう (${challengeList.length}もん)',
                      Colors.deepOrange.shade100,
                      MathMode.challenge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuCardByKey(String key) {
    switch (key) {
      case 'plus':     return _menuCard('➕ たしざん (しき)',         Colors.blue.shade100,   MathMode.plus);
      case 'minus':    return _menuCard('➖ ひきざん (しき)',         Colors.green.shade100,  MathMode.minus);
      case 'multi':    return _menuCard('✖ かけざん (しき)',          Colors.purple.shade100, MathMode.multi);
      case 'div':      return _menuCard('➗ わりざん (しき)',         Colors.teal.shade100,   MathMode.div);
      case 'story':    return _menuCard('📖 ぶんしょう もんだい',     Colors.orange.shade100, null, isStoryMenu: true);
      case 'puzzle':   return _menuCard('🧩 しきをつくる パズル',     Colors.yellow.shade200, null, isPuzzleMenu: true);
      case 'shopping': return _menuCard('💴 おかいもの もんだい',     Colors.pink.shade100,   MathMode.shopping);
      case 'compare':  return _menuCard('🔢 かずの おおきさ くらべ',  Colors.cyan.shade100,   MathMode.compare);
      case 'fillBoth': return _menuCard('🧮 むしくいざん チャレンジ', Colors.lime.shade200,   null, isFillBothMenu: true);
      case 'tens':     return _menuCard('🔟 10の まとまり',           Colors.teal.shade100,   MathMode.tens);
      case 'clock':    return _menuCard('🕐 とけい もんだい',          Colors.blue.shade100,   MathMode.clock);
      case 'shape':    return _menuCard('🔷 ずけい もんだい',          Colors.green.shade100,  MathMode.shape);
      default:         return const SizedBox.shrink();
    }
  }

  Widget _menuCard(
    String title,
    Color color,
    MathMode? mode, {
    bool isStoryMenu = false,
    bool isPuzzleMenu = false,
    bool isFillBothMenu = false,
  }) {
    return Card(
      color: color,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        onTap: () async {
          if (isStoryMenu) {
            await Navigator.push(context, MaterialPageRoute(
                builder: (_) => StoryMenuScreen(
                    maxNum: maxNum.toInt(), goal: goal.toInt(),
                    isSelect: isSelect, timeAttack: timeAttack)));
          } else if (isPuzzleMenu) {
            await Navigator.push(context, MaterialPageRoute(
                builder: (_) => PuzzleMenuScreen(
                    maxNum: maxNum.toInt(), goal: goal.toInt(),
                    isSelect: isSelect, timeAttack: timeAttack)));
          } else if (isFillBothMenu) {
            await Navigator.push(context, MaterialPageRoute(
                builder: (_) => FillBothMenuScreen(
                    maxNum: maxNum.toInt(), goal: goal.toInt(),
                    isSelect: isSelect, timeAttack: timeAttack)));
          } else if (mode != null) {
            await Navigator.push(context, MaterialPageRoute(
                builder: (_) => MathGame(
                    mode: mode, maxNum: maxNum.toInt(), goal: goal.toInt(),
                    isSelect: isSelect, timeAttack: timeAttack)));
          }
          _loadSettings();
        },
      ),
    );
  }
}