import 'package:flutter/material.dart';
import '../models/math_mode.dart';

// ── データクラス ──────────────────────────────────────────────────────

class ChartEntry {
  final MathMode mode;
  final String label;
  const ChartEntry(this.mode, this.label);
}

class ChartCategory {
  final String label;
  final List<ChartEntry> entries;
  const ChartCategory({required this.label, required this.entries});
}

// ── カテゴリ定義 ─────────────────────────────────────────────────────

const kChartCategories = [
  ChartCategory(
    label: '➕➖✖️➗ しき もんだい',
    entries: [
      ChartEntry(MathMode.plus,  'たしざん'),
      ChartEntry(MathMode.minus, 'ひきざん'),
      ChartEntry(MathMode.multi, 'かけざん'),
      ChartEntry(MathMode.div,   'わりざん'),
    ],
  ),
  ChartCategory(
    label: '📖 ぶんしょう もんだい',
    entries: [
      ChartEntry(MathMode.storyPlus,  'たし(話)'),
      ChartEntry(MathMode.storyMinus, 'ひき(話)'),
      ChartEntry(MathMode.storyMulti, 'かけ(話)'),
      ChartEntry(MathMode.storyDiv,   'わり(話)'),
    ],
  ),
  ChartCategory(
    label: '🧩 パズル・むしくい',
    entries: [
      ChartEntry(MathMode.puzzle,   'パズル'),
      ChartEntry(MathMode.fillBoth, 'むしくい'),
    ],
  ),
  ChartCategory(
    label: '💴🔢🔟 おかいもの・くらべ・まとまり',
    entries: [
      ChartEntry(MathMode.shopping, 'おかいもの'),
      ChartEntry(MathMode.compare,  'おおきさ'),
      ChartEntry(MathMode.tens,     '10まとまり'),
    ],
  ),
  ChartCategory(
    label: '🕐🔷 とけい・ずけい',
    entries: [
      ChartEntry(MathMode.clock, 'とけい'),
      ChartEntry(MathMode.shape, 'ずけい'),
    ],
  ),
];

// ── メインウィジェット ────────────────────────────────────────────────

class StatsChart extends StatelessWidget {
  final Map<MathMode, Map<String, int>> stats;
  const StatsChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final allModes = kChartCategories.expand((c) => c.entries.map((e) => e.mode));
    if (allModes.every((m) => (stats[m]?['total'] ?? 0) == 0)) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('まだ データが ありません',
              style: TextStyle(color: Colors.grey))),
        ),
      );
    }
    return Column(
      children: kChartCategories.map((cat) {
        final hasData = cat.entries.any((e) => (stats[e.mode]?['total'] ?? 0) > 0);
        if (!hasData) return const SizedBox.shrink();
        return StatsCategoryTile(category: cat, stats: stats);
      }).toList(),
    );
  }
}

// ── フリップダウン式カテゴリタイル ────────────────────────────────────

class StatsCategoryTile extends StatefulWidget {
  final ChartCategory category;
  final Map<MathMode, Map<String, int>> stats;
  const StatsCategoryTile({super.key, required this.category, required this.stats});

  @override
  State<StatsCategoryTile> createState() => _StatsCategoryTileState();
}

class _StatsCategoryTileState extends State<StatsCategoryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    int catTotal = 0, catCorrect = 0;
    for (final e in widget.category.entries) {
      catTotal   += widget.stats[e.mode]?['total']   ?? 0;
      catCorrect += widget.stats[e.mode]?['correct'] ?? 0;
    }
    final catPct   = catTotal == 0 ? 0 : (catCorrect * 100 / catTotal).round();
    final catColor = catPct >= 80 ? Colors.green
                   : catPct >= 50 ? Colors.orange
                   :                Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        // ヘッダー
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Expanded(
                child: Text(widget.category.label,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: catColor.withOpacity(0.5)),
                ),
                child: Text(catTotal == 0 ? '－' : '$catPct%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: catColor)),
              ),
              const SizedBox(width: 8),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
            ]),
          ),
        ),
        // 展開時
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: widget.category.entries.map((e) {
                final total   = widget.stats[e.mode]?['total']   ?? 0;
                final correct = widget.stats[e.mode]?['correct'] ?? 0;
                final rate    = total == 0 ? 0.0 : correct / total;
                final pct     = (rate * 100).round();
                final barColor = pct >= 80 ? Colors.green
                               : pct >= 50 ? Colors.orange
                               :             Colors.red;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    SizedBox(width: 64,
                        child: Text(e.label, style: const TextStyle(fontSize: 12))),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: rate, minHeight: 18,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              total == 0 ? Colors.grey.shade300 : barColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(width: 84,
                      child: Text(total == 0 ? '－' : '$pct% ($correct/$total)',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                    ),
                  ]),
                );
              }).toList(),
            ),
          ),
      ]),
    );
  }
}
