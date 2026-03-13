import 'dart:math';
import '../../models/question.dart';

class PlusGenerator {

  static Question generate() {

    final r = Random();

    int a = r.nextInt(10) + 1;
    int b = r.nextInt(10) + 1;

    int answer = a + b;

    List<int> choices = [
      answer,
      answer + 1,
      answer - 1,
      answer + 2
    ];

    choices.shuffle();

    return Question(
      text: "$a + $b = ?",
      answer: answer,
      choices: choices,
    );

  }

}