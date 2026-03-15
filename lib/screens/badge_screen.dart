import 'package:flutter/material.dart';
import '../models/badge_manager.dart';

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({super.key});
  @override State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  Set<String> _earned = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await BadgeManager.loadEarned();
    setState(() => _earned = e);
  }

  @override
  Widget build(BuildContext context) {
    final total   = kAllBadges.length;
    final gotCount = _earned.length;

    // カテゴリ分け
    final categories = [
      _Category('🌱 はじめて', ['first_question', 'first_perfect']),
      _Category('📝 もんだいすう', ['solve_10','solve_50','solve_100','solve_500','solve_1000']),
      _Category('🔥 れんぞくせいかい', ['streak_3','streak_5','streak_10']),
      _Category('📅 まいにち れんしゅう', ['days_3','days_7','days_30']),
      _Category('🎓 もーど はかせ', ['mode_plus','mode_minus','mode_multi','mode_div','mode_shopping','mode_clock','mode_shape','all_modes']),
      _Category('⚡ タイムアタック', ['time_10','time_20']),
      _Category('💪 にがてこくふく', ['wrong_clear']),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏅 バッジ コレクション'),
        backgroundColor: Colors.amber.shade200,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.amber.shade50,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 進捗サマリー
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(children: [
                    Text(
                      '$gotCount / $total',
                      style: TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: gotCount / total,
                        minHeight: 14,
                        backgroundColor: Colors.amber.shade100,
                        valueColor: AlwaysStoppedAnimation(Colors.amber.shade400),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      gotCount == total
                          ? '🎉 ぜんぶ あつめたよ！ すごすぎる！'
                          : 'あと ${total - gotCount} こで コンプリート！',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]),
                ),
                // カテゴリ別
                ...categories.map((cat) => _buildCategory(cat)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategory(_Category cat) {
    final badges = cat.ids
        .map((id) => BadgeManager.defById(id))
        .whereType<BadgeDef>()
        .toList();
    final earnedInCat = badges.where((b) => _earned.contains(b.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
          child: Row(children: [
            Text(cat.label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown)),
            const SizedBox(width: 8),
            Text('$earnedInCat / ${badges.length}',
                style: TextStyle(fontSize: 12, color: Colors.amber.shade600)),
          ]),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: badges.map((b) => _badgeCard(b)).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _badgeCard(BadgeDef b) {
    final got = _earned.contains(b.id);
    return Container(
      decoration: BoxDecoration(
        color: got ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: got ? Colors.amber.shade300 : Colors.grey.shade300,
          width: got ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            got ? b.emoji : '🔒',
            style: TextStyle(fontSize: got ? 28 : 22),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              got ? b.title : '？？？',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: got ? Colors.brown.shade600 : Colors.grey,
              ),
            ),
          ),
          if (got)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                b.desc,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
    );
  }
}

class _Category {
  final String label;
  final List<String> ids;
  const _Category(this.label, this.ids);
}
