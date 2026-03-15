import 'package:flutter/material.dart';

/// 学習カレンダーウィジェット
class CalendarSection extends StatelessWidget {
  final Map<String, int> calendarData;

  const CalendarSection({super.key, required this.calendarData});

  @override
  Widget build(BuildContext context) {
    final entries   = calendarData.entries.toList();
    final maxCount  = entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);
    final today     = DateTime.now();
    final todayKey  = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final totalDays = entries.where((e) => e.value > 0).length;
    final todayCount = calendarData[todayKey] ?? 0;
    const weekLabels = ['月', '火', '水', '木', '金', '土', '日'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _badge('きょう ${todayCount}もん',
                todayCount > 0 ? Colors.orange.shade50  : Colors.grey.shade50,
                todayCount > 0 ? Colors.orange.shade200 : Colors.grey.shade200,
                todayCount > 0 ? Colors.orange.shade700 : Colors.grey),
            const SizedBox(width: 10),
            _badge('35日で $totalDays 日れんしゅう',
                Colors.blue.shade50, Colors.blue.shade100, Colors.blue.shade700,
                fontSize: 12),
          ]),
          const SizedBox(height: 12),
          Row(children: weekLabels.map((w) => Expanded(
            child: Center(child: Text(w, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold,
              color: w == '日' ? Colors.red.shade400
                   : w == '土' ? Colors.blue.shade400
                   : Colors.grey.shade600,
            ))),
          )).toList()),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, mainAxisSpacing: 3, crossAxisSpacing: 3, childAspectRatio: 1.1),
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final entry     = entries[i];
              final count     = entry.value;
              final isToday   = entry.key == todayKey;
              final intensity = maxCount == 0 ? 0.0 : count / maxCount;
              final cellColor = count == 0       ? Colors.grey.shade100
                              : intensity < 0.33 ? Colors.orange.shade100
                              : intensity < 0.66 ? Colors.orange.shade300
                              :                    Colors.orange.shade500;
              final dayNum = int.tryParse(entry.key.split('-').last) ?? 0;
              return Tooltip(
                message: '${entry.key}  $count もん',
                child: Container(
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(4),
                    border: isToday
                        ? Border.all(color: Colors.deepOrange, width: 2)
                        : Border.all(color: Colors.grey.shade200, width: 0.5),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('$dayNum', style: TextStyle(
                      fontSize: 10,
                      color: count > 0
                          ? (intensity >= 0.66 ? Colors.white : Colors.orange.shade900)
                          : Colors.grey.shade400,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    )),
                    if (count > 0)
                      Text('$count', style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.bold,
                        color: intensity >= 0.66 ? Colors.white70 : Colors.orange.shade700,
                      )),
                  ]),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Text('0もん ', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ...[Colors.grey.shade100, Colors.orange.shade100,
                Colors.orange.shade300, Colors.orange.shade500]
                .map((c) => Container(
                  width: 14, height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)))),
            const Text(' おおい', style: TextStyle(fontSize: 10, color: Colors.grey)),
            const Spacer(),
            Container(width: 12, height: 12,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepOrange, width: 2),
                    borderRadius: BorderRadius.circular(2))),
            const Text(' きょう', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
        ]),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color border, Color textColor, {double fontSize = 13}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
        child: Text(text,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: textColor)),
      );
}
