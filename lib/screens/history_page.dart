import 'package:flutter/material.dart';
import '../models/math_mode.dart';
import '../models/managers.dart';

class HistoryPage extends StatefulWidget {
  final List<Map<String, dynamic>> history;
  const HistoryPage({super.key, required this.history});
  @override State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    // 新しい間違いが上に来るようにtimestamp降順でソート
    _items = List.from(widget.history)
      ..sort((a, b) =>
          ((b['timestamp'] as int?) ?? 0).compareTo((a['timestamp'] as int?) ?? 0));
  }

  String _opStr(MathMode m) {
    if (m.isPlus)              return '＋';
    if (m.isMinus)             return '－';
    if (m.isMulti)             return '×';
    if (m == MathMode.shopping) return '💴';
    if (m == MathMode.compare)  return '？';
    return '÷';
  }

  Future<void> _dismiss(Map<String, dynamic> q) async {
    await HistoryManager.dismissByTimestamp(q['timestamp'] as int? ?? 0);
    setState(() => _items.remove(q));
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final q in _items) {
      grouped.putIfAbsent(q['m'] as String? ?? '', () => []).add(q);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('間違い 履歴'),
        backgroundColor: Colors.blueGrey.shade200,
        centerTitle: true,
      ),
      body: _items.isEmpty
          ? const Center(
              child: Text('全て確認済みです 🎉',
                  style: TextStyle(fontSize: 16, color: Colors.grey)))
          : Container(
              color: Colors.blueGrey.shade50,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Wrap(spacing: 12, runSpacing: 6, children: [
                          _legend(Colors.red.shade100, Colors.red.shade300, '🔴 3回以上'),
                          _legend(Colors.orange.shade50, Colors.orange.shade200, '通常'),
                          const Text('✅ をタップすると 確認済みにできます',
                              style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ]),
                      ),
                      ...grouped.entries.map((e) {
                        final mode     = MathMode.fromString(e.key);
                        final problems = e.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                              child: Row(children: [
                                Text(mode.label,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey)),
                                const SizedBox(width: 8),
                                Text('${problems.length}問',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blueGrey.shade400)),
                              ]),
                            ),
                            ...problems.map((q) {
                              final n1    = q['n1'] as int;
                              final n2    = q['n2'] as int;
                              final t     = q['t']  as int;
                              final miss  = (q['miss'] as int?) ?? 1;
                              final qMode = MathMode.fromString(q['m'] as String);
                              final op    = _opStr(qMode);
                              final isHot = miss >= 3;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isHot ? Colors.red.shade50 : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isHot
                                        ? Colors.red.shade300
                                        : Colors.orange.shade200,
                                    width: isHot ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _questionText(q, qMode, n1, n2, op),
                                          style: TextStyle(
                                            fontSize: qMode == MathMode.shopping ? 13 : 18,
                                            fontWeight: FontWeight.bold,
                                            color: isHot
                                                ? Colors.red.shade700
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _answerText(q, qMode, n1, n2, t),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green.shade700),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isHot
                                          ? Colors.red.shade400
                                          : Colors.blueGrey.shade100,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text('$miss回',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isHot
                                              ? Colors.white
                                              : Colors.blueGrey.shade700,
                                        )),
                                  ),
                                  if (isHot)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Text('🔴',
                                          style: TextStyle(fontSize: 14)),
                                    ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_outline,
                                        color: Colors.green),
                                    tooltip: '確認済みにする',
                                    onPressed: () => _dismiss(q),
                                  ),
                                ]),
                              );
                            }),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String _questionText(Map<String, dynamic> q, MathMode mode, int n1, int n2, String op) {
    switch (mode) {
      case MathMode.clock:
        final cq = q['clockQuestion'] as String? ?? 'とけいもんだい';
        final ch = q['clockHour']   as int? ?? 0;
        final cm = q['clockMinute'] as int? ?? 0;
        final mStr = cm == 0 ? 'ちょうど' : '$cm ふん';
        return '🕐 $cq  ($ch じ $mStr)';
      case MathMode.shape:
        return '🔷 ${q['shapeQuestion'] ?? 'ずけいもんだい'}';
      case MathMode.shopping:
        return (q['isChange'] as int?) == 1
            ? '${q['itemA'] ?? '?'} ＋ ${q['itemB'] ?? '?'}  ${q['paid'] ?? '?'}えんだして おつり？'
            : '${q['itemA'] ?? '?'} ＋ ${q['itemB'] ?? '?'}  ぜんぶで なんえん？';
      case MathMode.compare:
        return '$n1 ？ $n2';
      case MathMode.fillBoth:
        final fOp  = q['fillOp']     as String? ?? '＋';
        final fA   = q['fillA']      as int?    ?? n1;
        final fB   = q['fillB']      as int?    ?? n2;
        final fLeft = (q['fillIsLeft'] as int?)  != 0;
        final left  = fLeft  ? '□' : '$fA';
        final right = !fLeft ? '□' : '$fB';
        final result = switch (fOp) {
          '＋' => fA + fB,
          '－' => fA - fB,
          '×'  => fA * fB,
          '÷'  => fB != 0 ? fA ~/ fB : 0,
          _    => 0,
        };
        return '$left $fOp $right ＝ $result';
      case MathMode.tens:
        final blocks = q['tensBlocks'] as int? ?? 0;
        final ones   = q['tensOnes']   as int? ?? 0;
        final askTotal = (q['tensAskTotal'] as int?) != 0;
        return askTotal
            ? '10のまとまり ${blocks}こ・ばら ${ones}こ → ぜんぶで？'
            : '${blocks * 10 + ones} は 10のまとまりが なんこ？';
      case MathMode.storyPlus:
      case MathMode.storyMinus:
      case MathMode.storyMulti:
      case MathMode.storyDiv:
        final story = q['story'] as String?;
        if (story != null && story.isNotEmpty) return story;
        return '$n1 $op $n2 ＝ ?';
      default:
        return '$n1 $op $n2 ＝ ?';
    }
  }

  String _answerText(Map<String, dynamic> q, MathMode mode, int n1, int n2, int t) {
    switch (mode) {
      case MathMode.clock:
        return '答え: ${q['clockAnswer'] ?? '-'}';
      case MathMode.shape:
        return '答え: ${q['shapeAnswer'] ?? '-'}';
      case MathMode.compare:
        return '答え: $n1 ${n1 > n2 ? '＞' : '＜'} $n2';
      case MathMode.fillBoth:
        final fLeft = (q['fillIsLeft'] as int?) != 0;
        final fA    = q['fillA'] as int? ?? n1;
        final fB    = q['fillB'] as int? ?? n2;
        return '答え: □ ＝ ${fLeft ? fA : fB}';
      case MathMode.tens:
        return '答え: $t';
      default:
        return '答え: $t';
    }
  }

  Widget _legend(Color bg, Color border, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: border),
    ),
    child: Text(label, style: const TextStyle(fontSize: 10)),
  );
}
