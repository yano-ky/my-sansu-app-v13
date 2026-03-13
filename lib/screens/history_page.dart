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
    _items = List.from(widget.history)
      ..sort((a, b) =>
          ((b['miss'] as int?) ?? 1).compareTo((a['miss'] as int?) ?? 1));
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
    final mode = MathMode.fromString(q['m'] as String);
    await HistoryManager.dismiss(mode, q['n1'] as int, q['n2'] as int);
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
                        final modeMiss = problems.fold<int>(
                            0, (s, q) => s + ((q['miss'] as int?) ?? 1));
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
                                Text('${problems.length}問・$modeMiss回',
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
                                          qMode == MathMode.shopping
                                              ? ((q['isChange'] as int?) == 1
                                                  ? '${q['itemA'] ?? '?'} + ${q['itemB'] ?? '?'}  ${q['paid'] ?? '?'}えんだして おつり？'
                                                  : '${q['itemA'] ?? '?'} + ${q['itemB'] ?? '?'}  ぜんぶで なんえん？')
                                              : qMode == MathMode.compare
                                                  ? '$n1 ？ $n2'
                                                  : '$n1 $op $n2 ＝ ?',
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
                                          qMode == MathMode.compare
                                              ? '答え: $n1 ${n1 > n2 ? '＞' : '＜'} $n2'
                                              : '答え: $t',
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
