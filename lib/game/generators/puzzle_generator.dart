import 'dart:math';
import '../../models/question.dart';

class PuzzleGenerator {

  static Question generate() {

    final r = Random();

    int a = r.nextInt(10);
    int b = r.nextInt(10);

    int answer = a + b;

    List<int> choices = [
      answer,
      answer + 2,
      answer - 1,
      answer + 3
    ];

    choices.shuffle();

    return Question(
      text: "$a + $b = ?",
      answer: answer,
      choices: choices,
    );

  }

}