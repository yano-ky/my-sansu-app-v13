import 'dart:math';
import '../question_result.dart';

class ShapeGenerator {
  static const _shapes = [
    _Shape('triangle',  'さんかくけい', 3, '三角形',  '角が3つ・辺が3つ'),
    _Shape('square',    'しかくけい',   4, '四角形',  '角が4つ・辺が4つ・全辺が等しい'),
    _Shape('rectangle', 'ちょうほうけい', 4, '長方形', '角が4つ・辺が4つ・向かい合う辺が等しい'),
    _Shape('circle',    'まる（えん）', 0, '円',      '角も辺もない・まんまる'),
    _Shape('pentagon',  'ごかくけい',   5, '五角形',  '角が5つ・辺が5つ'),
    _Shape('hexagon',   'ろっかくけい', 6, '六角形',  '角が6つ・辺が6つ'),
  ];

  static QuestionResult generate({required Random r}) {
    final shape  = _shapes[r.nextInt(_shapes.length)];
    final qType  = r.nextInt(3); // 0:なまえ 1:かどの数 2:へんの数

    String question, answer;
    List<String> choices;

    if (qType == 0) {
      // この図形の名前は？
      question = 'この ずけいは なに？';
      answer   = shape.jaName;
      final pool = _shapes.map((s) => s.jaName).where((n) => n != answer).toList()..shuffle(r);
      choices  = ([answer, ...pool.take(3)])..shuffle(r);
    } else if (qType == 1 && shape.corners > 0) {
      // 角の数
      question = '${shape.jaName} の かどは いくつ？';
      answer   = '${shape.corners} こ';
      final pool = [1,2,3,4,5,6,7,8].where((n) => n != shape.corners).toList()..shuffle(r);
      choices  = ([answer, ...pool.take(3).map((n) => '$n こ')])..shuffle(r);
    } else {
      // 図形の名前を見て形を選ぶ（形の説明）
      question = '${shape.jaName} は どれ？';
      answer   = shape.shapeName;
      final pool = _shapes.map((s) => s.shapeName).where((n) => n != answer).toList()..shuffle(r);
      choices  = ([answer, ...pool.take(3)])..shuffle(r);
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
  final String shapeName;
  final String desc;
  const _Shape(this.id, this.jaName, this.corners, this.shapeName, this.desc);
}
