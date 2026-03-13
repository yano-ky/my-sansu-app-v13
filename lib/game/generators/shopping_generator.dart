import 'dart:math';
import '../../models/question.dart';

class ShoppingGenerator {

  static Question generate() {

    final r = Random();

    int price = (r.nextInt(9) + 1) * 10;
    int paid = price + (r.nextInt(5) + 1) * 10;

    int answer = paid - price;

    List<int> choices = [
      answer,
      answer + 10,
      answer - 10,
      answer + 20
    ];

    choices.shuffle();

    return Question(
      text: "$paidえん だしたら\nおつりはいくら？",
      answer: answer,
      choices: choices,
    );

  }

}