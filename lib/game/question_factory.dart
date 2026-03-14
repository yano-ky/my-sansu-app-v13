import 'dart:math';
import '../models/math_mode.dart';
import 'question_result.dart';
import 'generators/plus_generator.dart';
import 'generators/minus_generator.dart';
import 'generators/multi_generator.dart';
import 'generators/div_generator.dart';
import 'generators/story_generator.dart';
import 'generators/puzzle_generator.dart';
import 'generators/shopping_generator.dart';
import 'generators/compare_generator.dart';
import 'generators/fillboth_generator.dart';
import 'generators/tens_generator.dart';
import 'generators/wrong_generator.dart';
import 'generators/challenge_generator.dart';
import 'generators/clock_generator.dart';
import 'generators/shape_generator.dart';

class QuestionFactory {
  /// [mode] に応じたジェネレーターを呼び出して QuestionResult を返す。
  /// 新モードを追加するときはここに case を1行追加するだけでよい。
  static QuestionResult generate({
    required MathMode mode,
    required int maxNum,
    int pLv = 1,
    int fillBothLv = 0,
    List<dynamic> wrongList = const [],
    List<Map<String, dynamic>> challengeList = const [],
    int challengeIdx = 0,
    Random? random,
  }) {
    final r = random ?? Random();
    switch (mode) {
      case MathMode.plus:
        return PlusGenerator.generate(maxNum: maxNum, r: r);
      case MathMode.minus:
        return MinusGenerator.generate(maxNum: maxNum, r: r);
      case MathMode.multi:
        return MultiGenerator.generate(r: r);
      case MathMode.div:
        return DivGenerator.generate(r: r);
      case MathMode.storyPlus:
      case MathMode.storyMinus:
      case MathMode.storyMulti:
      case MathMode.storyDiv:
        return StoryGenerator.generate(mode: mode, maxNum: maxNum, r: r);
      case MathMode.puzzle:
        return PuzzleGenerator.generate(maxNum: maxNum, pLv: pLv, r: r);
      case MathMode.shopping:
        return ShoppingGenerator.generate(r: r);
      case MathMode.compare:
        return CompareGenerator.generate(maxNum: maxNum, r: r);
      case MathMode.fillBoth:
        return FillBothGenerator.generate(maxNum: maxNum, fillBothLv: fillBothLv, r: r);
      case MathMode.tens:
        return TensGenerator.generate(r: r);
      case MathMode.wrong:
        return WrongGenerator.generate(wrongList: wrongList, r: r);
      case MathMode.challenge:
        return ChallengeGenerator.generate(
          challengeList: challengeList,
          idx: challengeIdx,
          r: r,
        );
      case MathMode.clock:
        return ClockGenerator.generate(r: r);
      case MathMode.shape:
        return ShapeGenerator.generate(r: r);
    }
  }
}
