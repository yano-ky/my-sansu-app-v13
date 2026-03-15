import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/math_mode.dart';
import '../models/badge_manager.dart';
import '../game/game_controller.dart';
import '../game/question_result.dart';

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
      mode:        widget.mode,
      maxNum:      widget.maxNum,
      goal:        widget.goal,
      isSelect:    widget.isSelect,
      timeAttack:  widget.timeAttack,
      pLv:         widget.pLv,
      fillBothLv:  widget.fillBothLv,
    );
    _ctrl.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerUpdate);
    _ctrl.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
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
    setState(() {});
  }

  // ── 回答ハンドラ ────────────────────────────────────────────────
  void _answerInt(int v)       => _ctrl.answerInt(v);
  void _answerString(String v) => _ctrl.answerString(v);

  // ── ビルド ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // ゲーム終了画面
    if (_ctrl.phase == GamePhase.finished) {
      return _buildFinished();
    }

    // ローディング
    if (_ctrl.question == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_ctrl.phase == GamePhase.reviewing
            ? 'ふくしゅうモード 📝'
            : 'さんすうゲーム'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              _buildQuestionArea(_ctrl.question!),
              const SizedBox(height: 32),
              _buildChoices(_ctrl.question!),
              const SizedBox(height: 24),
              Text('せいかい ${_ctrl.correct} / ${_ctrl.total}',
                  style: const TextStyle(fontSize: 20)),
              if (_ctrl.phase == GamePhase.playing &&
                  _ctrl.missedQuestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _ctrl.startReview()),
                  icon: const Icon(Icons.replay),
                  label: Text(
                      'まちがい ${_ctrl.missedQuestions.length}もん ふくしゅうする'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
              if (_ctrl.phase == GamePhase.reviewing) ...[
                const SizedBox(height: 8),
                Text('のこり ${_ctrl.remaining + 1} もん',
                    style:
                        const TextStyle(fontSize: 16, color: Colors.orange)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── ゲーム終了画面 ───────────────────────────────────────────────
  Widget _buildFinished() {
    final pct = _ctrl.total > 0
        ? (_ctrl.correct / _ctrl.total * 100).round()
        : 0;
    return Scaffold(
      appBar: AppBar(title: const Text('ゲームクリア！')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(pct == 100 ? '🎉' : pct >= 80 ? '😊' : '💪',
                style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            Text('せいかい ${_ctrl.correct} / ${_ctrl.total} もん',
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('せいかいりつ $pct%',
                style: const TextStyle(
                    fontSize: 22, color: Colors.orange)),
            const SizedBox(height: 40),
            if (_ctrl.missedQuestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _ctrl.startReview()),
                  icon: const Icon(Icons.replay),
                  label: Text(
                      'まちがい ${_ctrl.missedQuestions.length}もん ふくしゅうする'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ElevatedButton.icon(
              onPressed: () => setState(() => _ctrl.restart()),
              icon: const Icon(Icons.refresh),
              label: const Text('もういちどあそぶ'),
              style: ElevatedButton.styleFrom(
                textStyle: const TextStyle(fontSize: 20),
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 問題文エリア ─────────────────────────────────────────────────
  Widget _buildQuestionArea(QuestionResult q) {
    switch (widget.mode) {
      case MathMode.clock:
        return Column(children: [
          _ClockFace(hour: q.clockHour, minute: q.clockMinute),
          const SizedBox(height: 16),
          Text(q.clockQuestion,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
        ]);

      case MathMode.shape:
        return Column(children: [
          _ShapeFigure(shapeName: q.shapeName),
          const SizedBox(height: 16),
          Text(q.shapeQuestion,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
        ]);

      case MathMode.compare:
        return Text('${q.cmpA}  ？  ${q.cmpB}',
            style: const TextStyle(
                fontSize: 40, fontWeight: FontWeight.bold));

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
        return Text('$left ${q.fillOp} $right ＝ $result',
            style: const TextStyle(
                fontSize: 36, fontWeight: FontWeight.bold));

      case MathMode.shopping:
        final text = q.shopIsChange
            ? '${q.shopItemA}(${q.shopPriceA}円) と'
              ' ${q.shopItemB}(${q.shopPriceB}円)\n'
              '${q.shopPaid}円 だして おつりは？'
            : '${q.shopItemA}(${q.shopPriceA}円) と'
              ' ${q.shopItemB}(${q.shopPriceB}円)\n'
              'ぜんぶで なんえん？';
        return Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold));

      case MathMode.tens:
        final txt = q.tensAskTotal
            ? '10のまとまりが ${q.tensBlocks}こ、ばらが ${q.tensOnes}こ\nぜんぶで なんこ？'
            : '${q.tensBlocks * 10 + q.tensOnes} は 10のまとまりが なんこ？';
        return Text(txt,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold));

      default:
        final text = q.story.isNotEmpty
            ? q.story
            : '${q.n1} ${q.op} ${q.n2} ＝ ？';
        return Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 32, fontWeight: FontWeight.bold));
    }
  }

  // ── 選択肢エリア ─────────────────────────────────────────────────
  Widget _buildChoices(QuestionResult q) {
    switch (widget.mode) {
      case MathMode.clock:
        return _strButtons(q.clockChoices);
      case MathMode.shape:
        return _strButtons(q.shapeChoices);
      case MathMode.compare:
        return _strButtons(q.cmpChoices);
      case MathMode.fillBoth:
        return _intButtons(q.fillChoices);
      case MathMode.tens:
        return _intButtons(q.tensChoices);
      default:
        return _intButtons(q.choices);
    }
  }

  Widget _intButtons(List<int> choices) => Column(
        children: choices
            .map((c) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: ElevatedButton(
                    onPressed: () => _answerInt(c),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 60),
                      textStyle: const TextStyle(fontSize: 24),
                    ),
                    child: Text('$c'),
                  ),
                ))
            .toList(),
      );

  Widget _strButtons(List<String> choices) => Column(
        children: choices
            .map((c) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: ElevatedButton(
                    onPressed: () => _answerString(c),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 60),
                      textStyle: const TextStyle(fontSize: 22),
                    ),
                    child: Text(c),
                  ),
                ))
            .toList(),
      );
}

// ── 時計ウィジェット ──────────────────────────────────────────────
class _ClockFace extends StatelessWidget {
  final int hour, minute;
  const _ClockFace({required this.hour, required this.minute});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(180, 180),
        painter: _ClockPainter(hour: hour, minute: minute),
      );
}

class _ClockPainter extends CustomPainter {
  final int hour, minute;
  const _ClockPainter({required this.hour, required this.minute});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;

    canvas.drawCircle(c, r, Paint()..color = Colors.white);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 1; i <= 12; i++) {
      final a = (i * 30 - 90) * math.pi / 180;
      final p = Offset(c.dx + (r - 18) * math.cos(a),
                       c.dy + (r - 18) * math.sin(a));
      tp.text = TextSpan(
          text: '$i',
          style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.bold));
      tp.layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }

    _hand(canvas, c,
        ((hour % 12) + minute / 60.0) * 30 * math.pi / 180 - math.pi / 2,
        r * 0.5, 5, Colors.black87);
    _hand(canvas, c,
        minute * 6 * math.pi / 180 - math.pi / 2,
        r * 0.75, 3, Colors.black54);
    canvas.drawCircle(c, 5, Paint()..color = Colors.black87);
  }

  void _hand(Canvas canvas, Offset c, double a, double len, double w, Color col) {
    canvas.drawLine(
        c,
        Offset(c.dx + len * math.cos(a), c.dy + len * math.sin(a)),
        Paint()
          ..color = col
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_ClockPainter o) =>
      o.hour != hour || o.minute != minute;
}

// ── 図形ウィジェット ──────────────────────────────────────────────
class _ShapeFigure extends StatelessWidget {
  final String shapeName;
  const _ShapeFigure({required this.shapeName});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(140, 140),
        painter: _ShapePainter(shapeName: shapeName),
      );
}

class _ShapePainter extends CustomPainter {
  final String shapeName;
  const _ShapePainter({required this.shapeName});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = Colors.blue.shade200
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 10;

    switch (shapeName) {
      case 'circle':
        canvas.drawCircle(Offset(cx, cy), r, fill);
        canvas.drawCircle(Offset(cx, cy), r, line);
      case 'square':
        final rect = Rect.fromCenter(
            center: Offset(cx, cy), width: r * 1.8, height: r * 1.8);
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, line);
      case 'rectangle':
        final rect = Rect.fromCenter(
            center: Offset(cx, cy), width: r * 2.2, height: r * 1.3);
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, line);
      case 'triangle':
        final p = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy + r)
          ..lineTo(cx - r, cy + r)
          ..close();
        canvas.drawPath(p, fill);
        canvas.drawPath(p, line);
      default:
        final sides = switch (shapeName) {
          'pentagon' => 5,
          'hexagon'  => 6,
          _          => 4,
        };
        final p = Path();
        for (int i = 0; i < sides; i++) {
          final a = (i * 360 / sides - 90) * math.pi / 180;
          final x = cx + r * math.cos(a);
          final y = cy + r * math.sin(a);
          i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
        }
        p.close();
        canvas.drawPath(p, fill);
        canvas.drawPath(p, line);
    }
  }

  @override
  bool shouldRepaint(_ShapePainter o) => o.shapeName != shapeName;
}
