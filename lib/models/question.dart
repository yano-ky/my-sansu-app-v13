class Question {
  final String text; // questionText ではなく text に統一
  final int answer;
  final List<int> choices;

  Question({
    required this.text,
    required this.answer,
    required this.choices,
  });
}