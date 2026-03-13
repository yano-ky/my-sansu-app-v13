import 'dart:math';
import '../../models/question.dart';

class FillBothGenerator {

  static Question generate() {

    final r = Random();

    int a = r.nextInt(10);
    int b = r.nextInt(10);

    int answer = a + b;

    List<int> choices = [
      answer,
      answer + 1,
      answer - 1,
      answer + 2
    ];

    choices.shuffle();

    return Question(
      text: "$a + □ = $answer",
      answer: b,
      choices: choices,
    );

  }

}