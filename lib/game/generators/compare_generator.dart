import 'dart:math';
import '../../models/question.dart';

class CompareGenerator {

  static Question generate() {

    final r = Random();

    int a = r.nextInt(20) + 1;
    int b = r.nextInt(20) + 1;

    int answer = a > b ? a : b;

    List<int> choices = [a, b, a + 1, b + 1];

    choices.shuffle();

    return Question(
      text: "$a と $b\nどっちが おおきい？",
      answer: answer,
      choices: choices,
    );

  }

}