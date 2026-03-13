import 'package:flutter/material.dart';

import '../../models/math_mode.dart';
import '../../models/question.dart';
import '../../game/question_factory.dart';

class MathGameScreen extends StatefulWidget {

  final MathMode mode;

  const MathGameScreen({
    super.key,
    required this.mode,
  });

  @override
  State<MathGameScreen> createState() => _MathGameScreenState();
}

class _MathGameScreenState extends State<MathGameScreen> {

  Question? question;

  int correct = 0;
  int total = 0;

  @override
  void initState() {
    super.initState();
    generateQuestion();
  }

  void generateQuestion() {

    question = QuestionFactory.generate(widget.mode);

    setState(() {});
  }

  void checkAnswer(int value) {

    total++;

    if (value == question!.answer) {
      correct++;
    }

    generateQuestion();
  }

  @override
  Widget build(BuildContext context) {

    if (question == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(

      appBar: AppBar(
        title: const Text("さんすうゲーム"),
      ),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Text(
            question!.text,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 40),

          ...question!.choices.map((c) {

            return Padding(
              padding: const EdgeInsets.all(8),

              child: ElevatedButton(

                onPressed: () => checkAnswer(c),

                child: Text(
                  "$c",
                  style: const TextStyle(fontSize: 24),
                ),

              ),
            );

          }),

          const SizedBox(height: 30),

          Text(
            "せいかい $correct / $total",
            style: const TextStyle(fontSize: 20),
          ),

        ],
      ),
    );
  }
}