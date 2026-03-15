import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/math_mode.dart';
import '../game/question_factory.dart';
import '../game/question_result.dart';

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
    this.goal = 10,
    this.isSelect = true,
    this.timeAttack = false,
    this.pLv = 1,
    this.fillBothLv = 0,
  });

  @override
  State<MathGame> createState() => _MathGameState();
}

class _MathGameState extends State<MathGame> {
  QuestionResult? question;
  int correct = 0;
  int total = 0;
  List<QuestionResult> missedQuestions = [];
  bool isReviewMode = false;
  List<QuestionResult> reviewQueue = [];
  bool isGameOver = false;

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  void _generateQuestion() {
    setState(() {
      if (isReviewMode && reviewQueue.isNotEmpty) {
        question = reviewQueue.removeAt(0);
      } else if (isReviewMode && reviewQueue.isEmpty) {
        isGameOver = true;
      } else {
        question = QuestionFactory.generate(
          mode: widget.mode,
          maxNum: widget.maxNum,
          pLv: widget.pLv,
          fillBothLv: widget.fillBothLv,
        );
      }
    });
  }

  // 通常問題（int選択肢）の正誤判定
  void _checkAnswer(int value) {
    if (question == null) return;
    total++;
    if (value == question!.target) {
      correct++;
    } else {
      missedQuestions.add(question!);
    }
    _generateQuestion();
  }

  // 文字列選択肢（時計・図形・数の大小）の正誤判定
  void _checkStringAnswer(String value) {
    if (question == null) return;
    final q = question!;
    total++;
    final isCorrect = switch (widget.mode) {
      MathMode.clock   => value == q.clockAnswer,
      MathMode.shape   => value == q.shapeAnswer,
      MathMode.compare => value == q.correctSign,
      _                => false,
    };
    if (isCorrect) {
      correct++;
    } else {
      missedQuestions.add(q);
    }
    _generateQuestion();
  }

  void _startReview() {
    if (missedQuestions.isEmpty) return;
    setState(() {
      isReviewMode = true;
      reviewQueue = List.from(missedQuestions);
      missedQuestions.clear();
      correct = 0;
      total = 0;
    });
    _generateQuestion();
  }

  void _restartGame() {
    setState(() {
      isGameOver = false;
      isReviewMode = false;
      missedQuestions.clear();
      reviewQueue.clear();
      correct = 0;
      total = 0;
    });
    _generateQuestion();
  }

  @override
  Widget build(BuildContext context) {
    if (isGameOver) {
      return Scaffold(
        appBar: AppBar(title: const Text('ふくしゅうかんりょう！')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 20),
              const Text('ふくしゅうおわったよ！',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('せいかい $correct / $total',
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _restartGame,
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

    if (question == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isReviewMode ? 'ふくしゅうモード 📝' : 'さんすうゲーム'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildQuestionArea(),
          const SizedBox(height: 40),
          _buildChoices(),
          const SizedBox(height: 30),
          Text('せいかい $correct / $total',
              style: const TextStyle(fontSize: 20)),
          if (!isReviewMode && missedQuestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _startReview,
              icon: const Icon(Icons.replay),
              label: Text('まちがい ${missedQuestions.length}もん ふくしゅうする'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
          if (isReviewMode) ...[
            const SizedBox(height: 8),
            Text('のこり ${reviewQueue.length + 1} もん',
                style: const TextStyle(fontSize: 16, color: Colors.orange)),
          ],
        ],
      ),
    );
  }

  // ── 問題文エリア ──────────────────────────────────────────────
  Widget _buildQuestionArea() {
    final q = question!;

    // 時計
    if (widget.mode == MathMode.clock) {
      return Column(children: [
        _clockFace(q.clockHour, q.clockMinute),
        const SizedBox(height: 16),
        Text(q.clockQuestion,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ]);
    }

    // 図形
    if (widget.mode == MathMode.shape) {
      return Column(children: [
        _shapeWidget(q.shapeName),
        const SizedBox(height: 16),
        Text(q.shapeQuestion,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ]);
    }

    // 数の大小比較
    if (widget.mode == MathMode.compare) {
      return Text('${q.cmpA}  ？  ${q.cmpB}',
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold));
    }

    // 虫食い算
    // fillIsLeft=true → 左が□（□ op fillB = fillAns の結果）
    // fillIsLeft=false → 右が□（fillA op □ = fillAns の結果）
    if (widget.mode == MathMode.fillBoth) {
      final left  = q.fillIsLeft  ? '□' : '${q.fillA}';
      final right = !q.fillIsLeft ? '□' : '${q.fillB}';
      final result = switch (q.fillOp) {
        '＋' => q.fillA + q.fillB,
        '－' => q.fillA - q.fillB,
        '×' => q.fillA * q.fillB,
        '÷' => q.fillB != 0 ? q.fillA ~/ q.fillB : 0,
        _    => 0,
      };
      final display = '$left ${q.fillOp} $right ＝ $result';
      return Text(display,
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold));
    }

    // おかいもの
    if (widget.mode == MathMode.shopping) {
      final text = q.shopIsChange
          ? '${q.shopItemA}(${q.shopPriceA}円) と ${q.shopItemB}(${q.shopPriceB}円)\n${q.shopPaid}円 だして おつりは？'
          : '${q.shopItemA}(${q.shopPriceA}円) と ${q.shopItemB}(${q.shopPriceB}円)\nぜんぶで なんえん？';
      return Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
    }

    // 通常・文章問題
    final displayText = q.story.isNotEmpty
        ? q.story
        : '${q.n1} ${q.op} ${q.n2} ＝ ？';
    return Text(displayText,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold));
  }

  // ── 選択肢エリア ──────────────────────────────────────────────
  Widget _buildChoices() {
    final q = question!;

    // 文字列選択肢（時計・図形・数の大小）
    if (widget.mode == MathMode.clock) {
      return _stringChoiceButtons(q.clockChoices);
    }
    if (widget.mode == MathMode.shape) {
      return _stringChoiceButtons(q.shapeChoices);
    }
    if (widget.mode == MathMode.compare) {
      return _stringChoiceButtons(q.cmpChoices);
    }

    // 虫食い算
    if (widget.mode == MathMode.fillBoth) {
      return _intChoiceButtons(q.fillChoices);
    }

    // 10のまとまり
    if (widget.mode == MathMode.tens) {
      return _intChoiceButtons(q.tensChoices);
    }

    // 通常（int選択肢）
    return _intChoiceButtons(q.choices);
  }

  Widget _intChoiceButtons(List<int> choices) {
    return Column(
      children: choices.map((c) => Padding(
        padding: const EdgeInsets.all(8),
        child: ElevatedButton(
          onPressed: () => _checkAnswer(c),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(200, 60),
            textStyle: const TextStyle(fontSize: 24),
          ),
          child: Text('$c'),
        ),
      )).toList(),
    );
  }

  Widget _stringChoiceButtons(List<String> choices) {
    return Column(
      children: choices.map((c) => Padding(
        padding: const EdgeInsets.all(8),
        child: ElevatedButton(
          onPressed: () => _checkStringAnswer(c),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(200, 60),
            textStyle: const TextStyle(fontSize: 22),
          ),
          child: Text(c),
        ),
      )).toList(),
    );
  }

  // ── 時計の文字盤 ──────────────────────────────────────────────
  Widget _clockFace(int hour, int minute) {
    return CustomPaint(
      size: const Size(180, 180),
      painter: _ClockPainter(hour: hour, minute: minute),
    );
  }

  // ── 図形ウィジェット ──────────────────────────────────────────
  Widget _shapeWidget(String shapeName) {
    return CustomPaint(
      size: const Size(140, 140),
      painter: _ShapePainter(shapeName: shapeName),
    );
  }
}

// ── 時計描画 ──────────────────────────────────────────────────────
class _ClockPainter extends CustomPainter {
  final int hour;
  final int minute;
  const _ClockPainter({required this.hour, required this.minute});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final bgPaint = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawCircle(center, radius, borderPaint);

    // 数字
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final pos = Offset(
        center.dx + (radius - 18) * cos(angle),
        center.dy + (radius - 18) * sin(angle),
      );
      tp.text = TextSpan(
        text: '$i',
        style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold),
      );
      tp.layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // 短針（時）
    final hAngle = ((hour % 12) + minute / 60.0) * 30 * math.pi / 180 - math.pi / 2;
    _drawHand(canvas, center, hAngle, radius * 0.5, 5, Colors.black87);

    // 長針（分）
    final mAngle = minute * 6 * math.pi / 180 - math.pi / 2;
    _drawHand(canvas, center, mAngle, radius * 0.75, 3, Colors.black54);

    // 中心点
    canvas.drawCircle(center, 5, Paint()..color = Colors.black87);
  }

  void _drawHand(Canvas canvas, Offset center, double angle, double length,
      double width, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(center.dx + length * cos(angle), center.dy + length * sin(angle)),
      paint,
    );
  }

  static double cos(double a) => math.cos(a);
  static double sin(double a) => math.sin(a);

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.hour != hour || old.minute != minute;
}

// ── 図形描画 ──────────────────────────────────────────────────────
class _ShapePainter extends CustomPainter {
  final String shapeName;
  const _ShapePainter({required this.shapeName});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade200
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 10;

    switch (shapeName) {
      case 'circle':
        canvas.drawCircle(Offset(cx, cy), r, paint);
        canvas.drawCircle(Offset(cx, cy), r, border);
      case 'triangle':
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy + r)
          ..lineTo(cx - r, cy + r)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, border);
      case 'square':
        final rect = Rect.fromCenter(center: Offset(cx, cy), width: r * 1.8, height: r * 1.8);
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, border);
      case 'rectangle':
        final rect = Rect.fromCenter(center: Offset(cx, cy), width: r * 2.2, height: r * 1.3);
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, border);
      default:
        // pentagon, hexagon など正多角形
        final sides = switch (shapeName) {
          'pentagon' => 5,
          'hexagon'  => 6,
          _          => 4,
        };
        final path = Path();
        for (int i = 0; i < sides; i++) {
          final angle = (i * 360 / sides - 90) * math.pi / 180;
          final x = cx + r * _cos(angle);
          final y = cy + r * _sin(angle);
          if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, border);
    }
  }

  static double _cos(double a) => math.cos(a);
  static double _sin(double a) => math.sin(a);

  @override
  bool shouldRepaint(_ShapePainter old) => old.shapeName != shapeName;
}
