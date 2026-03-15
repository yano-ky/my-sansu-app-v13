import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'math_mode.dart';

// ── 統計管理 ──────────────────────────────────────────────────────────
class StatsManager {
  static Future<void> record(MathMode mode, bool correct) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'stats_${mode.name}';
    Map<String, dynamic> data = {};
    try { data = json.decode(prefs.getString(key) ?? '{}'); } catch (_) {}
    data['correct'] = ((data['correct'] as int?) ?? 0) + (correct ? 1 : 0);
    data['total']   = ((data['total']   as int?) ?? 0) + 1;
    await prefs.setString(key, json.encode(data));
  }

  static Future<Map<MathMode, Map<String, int>>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <MathMode, Map<String, int>>{};
    for (final mode in MathMode.values) {
      if (mode == MathMode.wrong) continue;
      try {
        final raw = prefs.getString('stats_${mode.name}');
        if (raw != null) {
          final d = json.decode(raw);
          result[mode] = {
            'correct': (d['correct'] as int?) ?? 0,
            'total':   (d['total']   as int?) ?? 0,
          };
        }
      } catch (_) {}
    }
    return result;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final mode in MathMode.values) {
      await prefs.remove('stats_${mode.name}');
    }
  }
}

// ── 間違い履歴管理 ────────────────────────────────────────────────────
class HistoryManager {
  static const _key = 'wrongHistory';

  static Future<void> recordWrong(
    MathMode mode, int n1, int n2, int target, {
    Map<String, dynamic>? extraData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> history = [];
    try { history = json.decode(prefs.getString(_key) ?? '[]'); } catch (_) {}
    final idx = history.indexWhere((q) =>
        q['m'] == mode.name && q['n1'] == n1 && q['n2'] == n2);
    if (idx >= 0) {
      history[idx]['miss'] = ((history[idx]['miss'] as int?) ?? 1) + 1;
      // 追加情報も更新
      if (extraData != null) history[idx].addAll(extraData);
    } else {
      final entry = <String, dynamic>{'m': mode.name, 'n1': n1, 'n2': n2, 't': target, 'miss': 1};
      if (extraData != null) entry.addAll(extraData);
      history.add(entry);
    }
    await prefs.setString(_key, json.encode(history));
  }

  static Future<List<Map<String, dynamic>>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      return List<Map<String, dynamic>>.from(
          (json.decode(raw) as List).map((e) => Map<String, dynamic>.from(e)));
    } catch (_) { return []; }
  }

  static Future<void> dismiss(MathMode mode, int n1, int n2) async {
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> history = [];
    try { history = json.decode(prefs.getString(_key) ?? '[]'); } catch (_) {}
    final idx = history.indexWhere((q) =>
        q['m'] == mode.name && q['n1'] == n1 && q['n2'] == n2);
    if (idx >= 0) {
      history[idx]['dismissed'] = true;
      await prefs.setString(_key, json.encode(history));
    }
  }

  static Future<List<Map<String, dynamic>>> loadActive() async {
    final all = await loadAll();
    return all.where((q) => q['dismissed'] != true).toList();
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// ── 学習カレンダー管理 ───────────────────────────────────────────────
class CalendarManager {
  static const _key = 'studyCalendar';

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static Future<void> recordQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> data = {};
    try { data = json.decode(prefs.getString(_key) ?? '{}'); } catch (_) {}
    final key = _todayKey();
    data[key] = ((data[key] as int?) ?? 0) + 1;
    await prefs.setString(_key, json.encode(data));
  }

  static Future<Map<String, int>> loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> data = {};
    try { data = json.decode(prefs.getString(_key) ?? '{}'); } catch (_) {}
    final result = <String, int>{};
    final now = DateTime.now();
    for (int i = 34; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final k = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      result[k] = (data[k] as int?) ?? 0;
    }
    return result;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// ── 挑戦状管理 ──────────────────────────────────────────────────────
class ChallengeManager {
  static const _key = 'challengeList';

  static Future<List<Map<String, dynamic>>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      return List<Map<String, dynamic>>.from(
          (json.decode(raw) as List).map((e) => Map<String, dynamic>.from(e)));
    } catch (_) { return []; }
  }

  static Future<void> save(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(list));
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}