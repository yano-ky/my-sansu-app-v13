import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/math_mode.dart';
import '../models/badge_manager.dart';
import '../game/game_controller.dart';
import '../game/question_result.dart';
import '../widgets/clock_face.dart';
import '../widgets/shape_figure.dart';

/// ゲーム画面 — 表示のみ担当。ロジックは GameController に委譲。
class MathGame extends StatefulWidget {
  final MathMode mode;
  final int maxNum;
  final int goal;
  final bool isSelect;
  final bool timeAttack;
  final int pLv;
  final int fillBothLv;

  const MathGame({
    super.key,
    required this.mode,
    this.maxNum = 10,
    this.goal   = 10,
    this.isSelect    = true,
    this.timeAttack  = false,
    this.pLv         = 1,
    this.fillBothLv  = 0,
  });

  @override
  State<MathGame> createState() => _MathGameState();
}

class _MathGameState extends State<MathGame> {
  late GameController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = GameController(
      mode:       widget.mode,
      maxNum:     widget.maxNum,
      goal:       widget.goal,
      isSelect:   widget.isSelect,
      timeAttack: widget.timeAttack,
      pLv:        widget.pLv,
      fillBothLv: widget.fillBothLv,
    );
    _ctrl.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onUpdate);
    _ctrl.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    // バッジ取得通知
    for (final id in _ctrl.lastNewBadges) {
      final def = BadgeManager.defById(id);
      if (def != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🎉 バッジかくとく！ ${def.emoji} ${def.title}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.amber.shade700,
        ));
      }
    }
    _ctrl.lastNewBadges = [];

    // ゲーム終了ダイアログ
    if (_ctrl.phase == GamePhase.finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showFinishDialog());
    }

    setState(() {});
  }

  // ── ゲーム終了ダイアログ ────────────────────────────────────────
  void _showFinishDialog() {
    final correct = _ctrl.correct;
    final total   = _ctrl.total;
    final pct     = total == 0 ? 0 : (correct * 100 / total).round();
    final wrong   = total - correct;

    String medal, comment;
    if (pct == 100)     { medal = '🥇'; comment = 'かんぺき！ すごすぎる！'; }
    else if (pct >= 80) { medal = '🥈'; comment = 'すばらしい！ よくできたね！'; }
    else if (pct >= 50) { medal = '🥉'; comment = 'よくがんばったね！'; }
    else                { medal = '⭐'; comment = 'つぎは もっと できるよ！'; }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Center(
          child: Text('🎊 おわったよ！ 🎊',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(medal, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 8),
          Text(comment,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
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
                _resultItem('✅ せいかい', correct, Colors.green),
                Container(width: 1, height: 44, color: Colors.orange.shade200),
                _resultItem('❌ ふせいかい', wrong, Colors.red),
              ]),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Colors.orange.shade200, height: 1),
              ),
              _resultItem('📊 せいかいりつ', pct, Colors.blue, suffix: '%'),
            ]),
          ),
          const SizedBox(height: 16),
          if (_ctrl.missedQuestions.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(c);
                setState(() => _ctrl.startReview());
              },
              icon: const Icon(Icons.replay),
              label: Text('まちがい ${_ctrl.missedQuestions.length}もん ふくしゅうする'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          const SizedBox(height: 8),
        ]),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () { Navigator.pop(c); Navigator.pop(context); },
              child: const Text('もどる', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _resultItem(String label, int value, Color color, {String suffix = 'もん'}) {
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      const SizedBox(height: 4),
      Text('$value$suffix',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  // ── ビルド ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_ctrl.phase == GamePhase.finished || _ctrl.question == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q        = _ctrl.question!;
    final progress = (_ctrl.total) / widget.goal;
    final titleText = _ctrl.phase == GamePhase.reviewing
        ? '📝 ふくしゅうモード  のこり ${_ctrl.remaining + 1} もん'
        : 'だい ${_ctrl.total + 1} もん / ${widget.goal} もん';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.orange.shade200,
        title: Text(titleText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        bottom: _ctrl.phase == GamePhase.playing
            ? PreferredSize(
                preferredSize: const Size.fromHeight(6),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.orange.shade100,
                  valueColor: AlwaysStoppedAnimation(Colors.orange.shade600),
                ),
              )
            : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(children: [
              _buildQuestionArea(q),
              const SizedBox(height: 24),
              _buildChoices(q),
              const SizedBox(height: 16),
              // 復習ボタン（通常モード中に間違いがあれば表示）
              if (_ctrl.phase == GamePhase.playing &&
                  _ctrl.missedQuestions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _ctrl.startReview()),
                    icon: const Icon(Icons.replay),
                    label: Text(
                        'まちがい ${_ctrl.missedQuestions.length}もん ふくしゅうする'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── 問題文エリア ─────────────────────────────────────────────────
  Widget _buildQuestionArea(QuestionResult q) {
    switch (widget.mode) {

      // 時計
      case MathMode.clock:
        return Column(children: [
          const SizedBox(height: 10),
          ClockFace(hour: q.clockHour, minute: q.clockMinute),
          const SizedBox(height: 16),
          _questionCard(q.clockQuestion, fontSize: 24),
        ]);

      // 図形
      case MathMode.shape:
        return Column(children: [
          const SizedBox(height: 10),
          ShapeFigure(shapeName: q.shapeName),
          const SizedBox(height: 16),
          _questionCard(q.shapeQuestion, fontSize: 24),
        ]);

      // 数の大小比較
      case MathMode.compare:
        return _questionCard('${q.cmpA}  ？  ${q.cmpB}', fontSize: 52);

      // 虫食い算
      case MathMode.fillBoth:
        final left   = q.fillIsLeft  ? '□' : '${q.fillA}';
        final right  = !q.fillIsLeft ? '□' : '${q.fillB}';
        final result = switch (q.fillOp) {
          '＋' => q.fillA + q.fillB,
          '－' => q.fillA - q.fillB,
          '×'  => q.fillA * q.fillB,
          '÷'  => q.fillB != 0 ? q.fillA ~/ q.fillB : 0,
          _    => 0,
        };
        return _questionCard('$left ${q.fillOp} $right ＝ $result', fontSize: 44);

      // おかいもの
      case MathMode.shopping:
        return _buildShoppingCard(q);

      // 10のまとまり
      case MathMode.tens:
        final txt = q.tensAskTotal
            ? '10のまとまりが ${q.tensBlocks}こ\nばらが ${q.tensOnes}こ\nぜんぶで なんこ？'
            : '${q.tensBlocks * 10 + q.tensOnes} は\n10のまとまりが なんこ？';
        return _questionCard(txt, fontSize: 28);

      // 通常・文章問題
      default:
        if (q.story.isNotEmpty) {
          return _questionCard(q.story, fontSize: 22);
        }
        return _questionCard('${q.n1} ${q.op} ${q.n2} ＝ ?', fontSize: 55);
    }
  }

  // カード風問題文
  Widget _questionCard(String text, {double fontSize = 36}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Center(
            child: Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, height: 1.4)),
          ),
        ),
      ),
    );
  }

  // おかいものカード
  Widget _buildShoppingCard(QuestionResult q) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 4,
        color: Colors.pink.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const Text('🛒 おみせやさん',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _shopItem(q.shopItemA, q.shopPriceA),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('＋',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ),
              _shopItem(q.shopItemB, q.shopPriceB),
            ]),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.pink.shade200),
              ),
              child: Text(
                q.shopIsChange
                    ? '💰 ${q.shopPaid}えん だしたら\nおつりは なんえん？'
                    : 'ぜんぶで なんえん？',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, height: 1.6),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _shopItem(String name, int price) {
    return Column(children: [
      Text(name.split(' ').first, style: const TextStyle(fontSize: 28)),
      const SizedBox(height: 4),
      Text(name.contains(' ') ? name.split(' ').last : name,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.pink.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('$price円',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    ]);
  }

  // ── 選択肢エリア ─────────────────────────────────────────────────
  Widget _buildChoices(QuestionResult q) {
    switch (widget.mode) {
      case MathMode.clock:
        return _strGrid(q.clockChoices);
      case MathMode.shape:
        return _strGrid(q.shapeChoices);
      case MathMode.compare:
        return _strGrid(q.cmpChoices);
      case MathMode.fillBoth:
        return _intGrid(q.fillChoices);
      case MathMode.tens:
        return _intGrid(q.tensChoices);
      default:
        return _intGrid(q.choices);
    }
  }

  // 2×2グリッドの数字ボタン
  Widget _intGrid(List<int> choices) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      childAspectRatio: 1.9,
      children: choices.map((c) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          backgroundColor: Colors.white,
          foregroundColor: Colors.deepOrange,
          elevation: 3,
          side: BorderSide(color: Colors.orange.shade200, width: 2),
        ),
        onPressed: () => _ctrl.answerInt(c),
        child: Text('$c'),
      )).toList(),
    );
  }

  // 文字列選択肢（時計・図形・大小）
  Widget _strGrid(List<String> choices) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      childAspectRatio: 2.2,
      children: choices.map((c) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          backgroundColor: Colors.white,
          foregroundColor: Colors.deepOrange,
          elevation: 3,
          side: BorderSide(color: Colors.orange.shade200, width: 2),
        ),
        onPressed: () => _ctrl.answerString(c),
        child: Text(c, textAlign: TextAlign.center),
      )).toList(),
    );
  }
}
