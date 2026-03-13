import 'dart:math';
import '../../models/question.dart';

class TensGenerator {

  static Question generate() {

    final r = Random();

    int a = (r.nextInt(9) + 1) * 10;
    int b = (r.nextInt(9) + 1) * 10;

    int answer = a + b;

    List<int> choices = [
      answer,
      answer + 10,
      answer - 10,
      answer + 20
    ];

    choices.shuffle();

    return Question(
      text: "$a + $b = ?",
      answer: answer,
      choices: choices,
    );

  }

}