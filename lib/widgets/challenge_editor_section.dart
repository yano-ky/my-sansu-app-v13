import 'package:flutter/material.dart';
import '../models/managers.dart';

/// 挑戦状エディターウィジェット
class ChallengeEditorSection extends StatefulWidget {
  const ChallengeEditorSection({super.key});

  @override
  State<ChallengeEditorSection> createState() => _ChallengeEditorSectionState();
}

class _ChallengeEditorSectionState extends State<ChallengeEditorSection> {
  final _fromCtrl = TextEditingController();
  final _msgCtrl  = TextEditingController();
  final _qCtrl    = TextEditingController();
  final _ansCtrl  = TextEditingController();

  @override
  void dispose() {
    _fromCtrl.dispose();
    _msgCtrl.dispose();
    _qCtrl.dispose();
    _ansCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: ChallengeManager.loadAll(),
            builder: (ctx, snap) {
              final list = snap.data ?? [];
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('まだ ちょうせんじょうが ありません',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                );
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('登録済み ${list.length} 問',
                    style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                const SizedBox(height: 6),
                ...list.asMap().entries.map((e) {
                  final i = e.key; final item = e.value;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.deepOrange.shade100,
                      child: Text('${i + 1}', style: const TextStyle(fontSize: 11)),
                    ),
                    title: Text(item['question'] as String? ?? '',
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                        '答え: ${item["answer"]}  from: ${item["from"] ?? ""}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () async {
                        final newList = List<Map<String, dynamic>>.from(list)..removeAt(i);
                        await ChallengeManager.save(newList);
                        setState(() {});
                      },
                    ),
                  );
                }),
                const Divider(),
              ]);
            },
          ),
          const Text('＋ あたらしく つくる',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 10),
          TextField(controller: _fromCtrl,
              decoration: const InputDecoration(
                  labelText: '差出人（例：パパ、ママ）',
                  border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 8),
          TextField(controller: _msgCtrl,
              decoration: const InputDecoration(
                  labelText: 'ひとことメッセージ（任意）',
                  hintText: '例：がんばれ！パパより',
                  border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 8),
          TextField(controller: _qCtrl, maxLines: 2,
              decoration: const InputDecoration(
                  labelText: '問題文',
                  hintText: '例：12＋34は？',
                  border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 8),
          TextField(controller: _ansCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: '答え（数字）',
                  border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('ちょうせんじょうに 追加'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
              onPressed: () async {
                final ans = int.tryParse(_ansCtrl.text);
                if (_qCtrl.text.isEmpty || ans == null) return;
                final list = await ChallengeManager.loadAll();
                list.add({
                  'from':     _fromCtrl.text.isEmpty ? 'パパ・ママ' : _fromCtrl.text,
                  'message':  _msgCtrl.text,
                  'question': _qCtrl.text,
                  'answer':   ans,
                });
                await ChallengeManager.save(list);
                _fromCtrl.clear(); _msgCtrl.clear();
                _qCtrl.clear(); _ansCtrl.clear();
                setState(() {});
              },
            ),
          ),
        ]),
      ),
    );
  }
}
