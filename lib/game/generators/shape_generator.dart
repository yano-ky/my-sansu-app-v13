import 'dart:math';
import '../question_result.dart';

class ShapeGenerator {
  static const _shapes = [
    _Shape('triangle',   'さんかくけい', 3, '三角形'),
    _Shape('square',     'しかくけい',   4, '四角形'),
    _Shape('rectangle',  'ちょうほうけい', 4, '長方形'),
    _Shape('circle',     'まる（えん）', 0, '円'),
    _Shape('pentagon',   'ごかくけい',   5, '五角形'),
    _Shape('hexagon',    'ろっかくけい', 6, '六角形'),
  ];

  static QuestionResult generate({required Random r}) {
    final shape  = _shapes[r.nextInt(_shapes.length)];
    // circle は角の数問題を出さない
    final maxType = shape.corners == 0 ? 1 : 3;
    final qType  = r.nextInt(maxType);

    String question, answer;
    List<String> choices;

    if (qType == 0) {
      // この図形の名前は？
      question = 'この ずけいは なに？';
      answer   = shape.jaName;
      final pool = _shapes.map((s) => s.jaName).where((n) => n != answer).toList()..shuffle(r);
      choices  = [answer, ...pool.take(3)]..shuffle(r);
    } else if (qType == 1) {
      // かどは いくつ？（かどがある図形のみ）
      question = '${shape.jaName} の かどは いくつ？';
      answer   = '${shape.corners} こ';
      final pool = [2, 3, 4, 5, 6, 7, 8]
          .where((n) => n != shape.corners)
          .map((n) => '$n こ')
          .toList()..shuffle(r);
      choices  = [answer, ...pool.take(3)]..shuffle(r);
    } else {
      // へんは いくつ？
      question = '${shape.jaName} の へんは いくつ？';
      answer   = '${shape.corners} ほん';
      final pool = [2, 3, 4, 5, 6, 7, 8]
          .where((n) => n != shape.corners)
          .map((n) => '$n ほん')
          .toList()..shuffle(r);
      choices  = [answer, ...pool.take(3)]..shuffle(r);
    }

    return QuestionResult(
      target: 0,
      shapeName:     shape.id,
      shapeQuestion: question,
      shapeChoices:  choices,
      shapeAnswer:   answer,
    );
  }
}

class _Shape {
  final String id;
  final String jaName;
  final int corners;
  final String kanjiName;
  const _Shape(this.id, this.jaName, this.corners, this.kanjiName);
}
