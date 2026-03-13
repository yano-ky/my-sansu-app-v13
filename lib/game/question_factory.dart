import '../../models/math_mode.dart';
import '../../models/question.dart';
import 'generators/plus_generator.dart';
import 'generators/minus_generator.dart';
import 'generators/shopping_generator.dart';
import 'generators/compare_generator.dart';
import 'generators/fillboth_generator.dart';
import 'generators/puzzle_generator.dart';
import 'generators/tens_generator.dart';

class QuestionFactory {

  static Question generate(MathMode mode) {
    switch (mode) {
      case MathMode.plus:
        return PlusGenerator.generate();
      case MathMode.minus:
        return MinusGenerator.generate();
      case MathMode.shopping:
        return ShoppingGenerator.generate();
      case MathMode.compare:
        return CompareGenerator.generate();
      case MathMode.fillBoth:
        return FillBothGenerator.generate();
      case MathMode.puzzle:
        return PuzzleGenerator.generate();
      case MathMode.tens:
        return TensGenerator.generate();
    }
  }

}