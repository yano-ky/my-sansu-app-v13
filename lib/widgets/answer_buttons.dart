import 'package:flutter/material.dart';

class AnswerButtons extends StatelessWidget {
  final List<int> choices;
  final void Function(int) onAnswer;

  const AnswerButtons({
    super.key,
    required this.choices,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: choices.map((c) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: ElevatedButton(
            onPressed: () => onAnswer(c),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 60),
              textStyle: const TextStyle(fontSize: 24),
            ),
            child: Text("$c"),
          ),
        );
      }).toList(),
    );
  }
}