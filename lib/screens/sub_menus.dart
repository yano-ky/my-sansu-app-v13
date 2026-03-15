import 'package:flutter/material.dart';
import '../models/math_mode.dart';
import 'math_game_screen.dart';

// ── ストーリーメニュー ────────────────────────────────────────────────
class StoryMenuScreen extends StatelessWidget {
  final int maxNum, goal;
  final bool isSelect, timeAttack;
  const StoryMenuScreen({
    super.key,
    required this.maxNum,
    required this.goal,
    required this.isSelect,
    this.timeAttack = false,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('どの おはなし？'),
      backgroundColor: Colors.orange.shade200,
      centerTitle: true,
    ),
    body: Container(
      color: Colors.orange.shade50,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        _item(context, '➕ たしざん おはなし', MathMode.storyPlus,  Colors.blue.shade100),
        _item(context, '➖ ひきざん おはなし', MathMode.storyMinus, Colors.green.shade100),
        _item(context, '✖ かけざん おはなし',  MathMode.storyMulti, Colors.purple.shade100),
        _item(context, '➗ わりざん おはなし', MathMode.storyDiv,   Colors.teal.shade100),
      ]),
    ),
  );

  Widget _item(BuildContext ctx, String title, MathMode mode, Color color) =>
      Card(
        color: color,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          title: Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          onTap: () => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => MathGame(
                  mode: mode, maxNum: maxNum, goal: goal,
                  isSelect: isSelect, timeAttack: timeAttack))),
        ),
      );
}

// ── パズルメニュー ───────────────────────────────────────────────────
class PuzzleMenuScreen extends StatelessWidget {
  final int maxNum, goal;
  final bool isSelect, timeAttack;
  const PuzzleMenuScreen({
    super.key,
    required this.maxNum,
    required this.goal,
    required this.isSelect,
    this.timeAttack = false,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('パズルに ちょうせん！'),
      backgroundColor: Colors.orange.shade200,
      centerTitle: true,
    ),
    body: Container(
      color: Colors.orange.shade50,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        _item(context, '➕ たしざん パズル',       Colors.green.shade100,  1),
        _item(context, '➖ ひきざん パズル',       Colors.blue.shade100,   2),
        _item(context, '➕➕ 3つの たしざん',     Colors.purple.shade100, 3),
        _item(context, '🌀 ぜんぶ まざった パズル', Colors.red.shade100,   4),
      ]),
    ),
  );

  Widget _item(BuildContext ctx, String title, Color color, int lv) =>
      Card(
        color: color,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          title: Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          onTap: () => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => MathGame(
                  mode: MathMode.puzzle, maxNum: maxNum, goal: goal,
                  isSelect: isSelect, timeAttack: timeAttack, pLv: lv))),
        ),
      );
}

// ── むしくいざんメニュー ───────────────────────────────────────────────
class FillBothMenuScreen extends StatelessWidget {
  final int maxNum, goal;
  final bool isSelect, timeAttack;
  const FillBothMenuScreen({
    super.key,
    required this.maxNum,
    required this.goal,
    required this.isSelect,
    this.timeAttack = false,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('レベルを えらぼう'),
      backgroundColor: Colors.lime.shade300,
      centerTitle: true,
    ),
    body: Container(
      color: Colors.lime.shade50,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        _item(context, '➕ たしざんだけ', Colors.green.shade100,  1),
        _item(context, '➖ ひきざんだけ', Colors.blue.shade100,   2),
        _item(context, '✖ かけざんだけ',  Colors.purple.shade100, 3),
        _item(context, '➗ わりざんだけ', Colors.teal.shade100,   4),
        _item(context, '🌀 ぜんぶ まざった', Colors.orange.shade100, 5),
      ]),
    ),
  );

  Widget _item(BuildContext ctx, String title, Color color, int lv) =>
      Card(
        color: color,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          title: Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18)),
          onTap: () => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => MathGame(
                  mode: MathMode.fillBoth, maxNum: maxNum, goal: goal,
                  isSelect: isSelect, timeAttack: timeAttack,
                  fillBothLv: lv))),
        ),
      );
}
