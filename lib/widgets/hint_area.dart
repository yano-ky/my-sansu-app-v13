import 'package:flutter/material.dart';

class HintArea extends StatelessWidget {
  final int hintLevel;
  final String op;
  final int n1;
  final int n2;
  final int target;
  final String emoji;

  const HintArea({
    super.key,
    required this.hintLevel,
    required this.op,
    required this.n1,
    required this.n2,
    required this.target,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hintLevel == 1 ? Colors.amber.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hintLevel == 1 ? Colors.amber.shade200 : Colors.orange.shade300,
        ),
      ),
      child: Column(children: [
        Text(
          hintLevel == 1 ? '💡 ヒント①' : '💡💡 ヒント②',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: hintLevel == 1 ? Colors.amber.shade800 : Colors.orange.shade800,
          ),
        ),
        const SizedBox(height: 10),
        if (op == '＋') _hintPlus(hintLevel),
        if (op == '－') _hintMinus(hintLevel),
        if (op == '×') _hintMulti(hintLevel),
        if (op == '÷') _hintDiv(hintLevel),
      ]),
    );
  }

  Widget _emojiWrap(String em, int count, {double size = 24}) {
    const int cap = 20;
    if (count <= cap) {
      return Wrap(
        alignment: WrapAlignment.center,
        children: List.generate(count, (_) => Text(em, style: TextStyle(fontSize: size))),
      );
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Wrap(children: List.generate(cap, (_) => Text(em, style: TextStyle(fontSize: size)))),
      Text(' … ×$count', style: TextStyle(fontSize: size * 0.7, color: Colors.grey)),
    ]);
  }

  Widget _hintPlus(int level) {
    if (level == 1) {
      return Text(
        '$n1 と $n2 を あわせると いくつ？\nひとつずつ かぞえて みよう！',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, height: 1.6),
      );
    }
    return Column(children: [
      _emojiWrap(emoji, n1, size: 26),
      const Padding(padding: EdgeInsets.symmetric(vertical: 4),
          child: Text('➕', style: TextStyle(fontSize: 22))),
      _emojiWrap(emoji, n2, size: 26),
      const SizedBox(height: 6),
      Text('ぜんぶで $target こ！',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
    ]);
  }

  Widget _hintMinus(int level) {
    if (level == 1) {
      return Text(
        '$n1 から $n2 を とると いくつ のこる？\n$n1 から ひとつずつ へらして みよう！',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, height: 1.6),
      );
    }
    return Column(children: [
      _emojiWrap(emoji, target, size: 26),
      const SizedBox(height: 4),
      Text('🍴 の $n2 こ を とると…',
          style: const TextStyle(fontSize: 14, color: Colors.grey)),
      const SizedBox(height: 4),
      _emojiWrap(emoji, target, size: 26),
      const SizedBox(height: 6),
      Text('$target こ のこる！',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
    ]);
  }

  Widget _hintMulti(int level) {
    if (level == 1) {
      return Text(
        '$n2 こずつの グループが $n1 つ あるよ！\nグループを たしていくと いくつ？',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, height: 1.6),
      );
    }
    return Column(children: [
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: List.generate(n1, (i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.purple.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.purple.shade50,
          ),
          child: Column(children: [
            Text('グループ ${i + 1}',
                style: TextStyle(fontSize: 10, color: Colors.purple.shade700)),
            Wrap(children: List.generate(
                n2, (_) => const Text('🍬', style: TextStyle(fontSize: 22)))),
          ]),
        )),
      ),
      const SizedBox(height: 8),
      Text('$n2 × $n1 ＝ $target',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
    ]);
  }

  Widget _hintDiv(int level) {
    if (level == 1) {
      return Text(
        '$n1 こを $n2 にんで おなじかずずつ わけると\nひとり なんこ もらえる？',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, height: 1.6),
      );
    }
    return Column(children: [
      Text('$n1 こを $n2 にんに わけると…',
          style: const TextStyle(fontSize: 14, color: Colors.grey)),
      const SizedBox(height: 8),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: List.generate(n2, (i) => Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.teal.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.teal.shade50,
          ),
          child: Column(children: [
            Text('${i + 1}にんめ',
                style: TextStyle(fontSize: 10, color: Colors.teal.shade700)),
            Wrap(children: List.generate(
                target, (_) => Text(emoji, style: const TextStyle(fontSize: 20)))),
          ]),
        )),
      ),
      const SizedBox(height: 8),
      Text('ひとり $target こ！',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
    ]);
  }
}
