import 'package:flutter/material.dart';
import '../screens/badge_screen.dart';

/// 週間レポートウィジェット
class WeeklyReportSection extends StatelessWidget {
  final Map<String, int> calendarData;
  final Map<dynamic, Map<String, int>> stats;

  const WeeklyReportSection({
    super.key,
    required this.calendarData,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    int weekTotal = 0, weekDays = 0;
    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      final k = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      final v = calendarData[k] ?? 0;
      if (v > 0) { weekTotal += v; weekDays++; }
    }
    final prevTotal = (() {
      int t = 0;
      for (int i = 7; i < 14; i++) {
        final d = now.subtract(Duration(days: i));
        final k = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
        t += calendarData[k] ?? 0;
      }
      return t;
    })();
    final diff = weekTotal - prevTotal;
    final diffStr = diff > 0 ? '▲$diff もん' : diff < 0 ? '▼${-diff} もん' : '±0';
    final diffColor = diff > 0 ? Colors.green : diff < 0 ? Colors.red : Colors.grey;

    final totalStat   = stats.values.fold(0, (s, m) => s + (m['total']   ?? 0));
    final correctStat = stats.values.fold(0, (s, m) => s + (m['correct'] ?? 0));
    final overallPct  = totalStat == 0 ? 0 : (correctStat * 100 / totalStat).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: _stat('今週の問題数', '$weekTotal もん', Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _stat('れんしゅう日数', '$weekDays / 7 日', Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _stat('全体正解率', '$overallPct %', Colors.green)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(children: [
              const Text('先週比', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 8),
              Text(diffStr,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: diffColor)),
              const Spacer(),
              Text('先週: $prevTotal もん',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ),
          const SizedBox(height: 12),
          // 今週7日バーグラフ
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final d = now.subtract(Duration(days: 6 - i));
              final k = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
              final v = calendarData[k] ?? 0;
              final maxV = List.generate(7, (j) {
                final dd = now.subtract(Duration(days: 6-j));
                final kk = '${dd.year}-${dd.month.toString().padLeft(2,'0')}-${dd.day.toString().padLeft(2,'0')}';
                return calendarData[kk] ?? 0;
              }).fold(1, (a, b) => a > b ? a : b);
              final h = v == 0 ? 4.0 : (v / maxV * 60).clamp(8.0, 60.0);
              final isToday = i == 6;
              final weekDay = ['月','火','水','木','金','土','日'][d.weekday - 1];
              return Expanded(child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (v > 0) Text('$v', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Container(
                    height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isToday ? Colors.orange : Colors.orange.shade200,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(weekDay,
                      style: TextStyle(
                          fontSize: 10,
                          color: isToday ? Colors.orange : Colors.grey)),
                ],
              ));
            }),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
              side: BorderSide(color: Colors.amber.shade300),
              foregroundColor: Colors.brown,
              backgroundColor: Colors.amber.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Text('🏅', style: TextStyle(fontSize: 16)),
            label: const Text('バッジ コレクションを みる', style: TextStyle(fontSize: 13)),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BadgeScreen())),
          ),
        ]),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center),
    ]),
  );
}