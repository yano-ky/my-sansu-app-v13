import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/math_mode.dart';
import '../models/managers.dart';
import '../models/badge_manager.dart';
import 'question_factory.dart';
import 'question_result.dart';

/// ゲームの状態
enum GamePhase { playing, reviewing, finished }

/// ゲームのロジック・記録をすべて担当するコントローラー
/// UIは持たず、notifyListeners() で画面に変化を通知する
class GameController extends ChangeNotifier {
  final MathMode mode;
  final int maxNum;
  final int goal;
  final bool isSelect;
  final bool timeAttack;
  final int pLv;
  final int fillBothLv;

  List<dynamic> wrongList = [];
  List<Map<String, dynamic>> challengeList = [];
  int _challengeIdx = 0;

  GameController({
    required this.mode,
    this.maxNum = 10,
    this.goal = 10,
    this.isSelect = true,
    this.timeAttack = false,
    this.pLv = 1,
    this.fillBothLv = 0,
  }) {
    _init();
  }

  Future<void> _init() async {
    if (mode == MathMode.wrong) {
      final prefs = await _getPrefs();
      try {
        final s = prefs.getString('wrongList');
        if (s != null) wrongList = json.decode(s);
      } catch (_) {}
      if (wrongList.isEmpty) {
        phase = GamePhase.finished;
        notifyListeners();
        return;
      }
    } else if (mode == MathMode.challenge) {
      challengeList = await ChallengeManager.loadAll();
      if (challengeList.isEmpty) {
        phase = GamePhase.finished;
        notifyListeners();
        return;
      }
    }
    _next();
    notifyListeners();
  }

  Future<dynamic> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // ── 状態 ────────────────────────────────────────────────────────
  QuestionResult? question;
  int correct = 0;
  int total   = 0;
  int streak  = 0;
  GamePhase phase = GamePhase.playing;

  final List<QuestionResult> _missed  = [];
  final List<QuestionResult> _review  = [];

  List<QuestionResult> get missedQuestions => List.unmodifiable(_missed);
  int get remaining => _review.length;

  // 最後に取得したバッジ（UI表示用）
  List<String> lastNewBadges = [];

  // ── 公開API ─────────────────────────────────────────────────────

  /// int選択肢での回答（通常問題・虫食い・おかいもの・10のまとまりなど）
  Future<void> answerInt(int value) async {
    if (question == null) return;
    final q = question!;
    final isCorrect = value == q.target;
    await _judge(q, isCorrect);
  }

  /// 文字列選択肢での回答（時計・図形・数の大小）
  Future<void> answerString(String value) async {
    if (question == null) return;
    final q = question!;
    final isCorrect = switch (mode) {
      MathMode.clock   => value == q.clockAnswer,
      MathMode.shape   => value == q.shapeAnswer,
      MathMode.compare => value == q.correctSign,
      _                => false,
    };
    await _judge(q, isCorrect);
  }

  /// 復習モードを開始する
  void startReview() {
    if (_missed.isEmpty) return;
    _review
      ..clear()
      ..addAll(_missed);
    _missed.clear();
    correct = 0;
    total   = 0;
    phase   = GamePhase.reviewing;
    _next();
    notifyListeners();
  }

  /// もういちどあそぶ
  void restart() {
    correct = 0;
    total   = 0;
    streak  = 0;
    _challengeIdx = 0;
    _missed.clear();
    _review.clear();
    lastNewBadges = [];
    phase = GamePhase.playing;
    _next();
    notifyListeners();
  }

  // ── 内部処理 ─────────────────────────────────────────────────────

  Future<void> _judge(QuestionResult q, bool isCorrect, {String? wrongAnswer}) async {
    total++;
    if (isCorrect) {
      correct++;
      streak++;
    } else {
      if (phase == GamePhase.playing) _missed.add(q); // 復習中は追加しない
      streak = 0;
    }

    // 統計・履歴・バッジを記録（復習モードは記録しない）
    if (phase == GamePhase.playing) {
      await _record(q, isCorrect, wrongAnswer: wrongAnswer);
    }

    _next();
    notifyListeners();
  }

  void _next() {
    if (phase == GamePhase.reviewing) {
      if (_review.isNotEmpty) {
        question = _review.removeAt(0);
      } else {
        // 復習おわり → ゲーム終了
        phase = GamePhase.finished;
        question = null;
      }
      return;
    }
    // 通常モード
    _checkGoal();
  }

  void _checkGoal() {
    if (phase == GamePhase.playing && total >= goal) {
      phase = GamePhase.finished;
      question = null;
      return;
    }
    // challengeモードはインデックス管理
    if (mode == MathMode.challenge) {
      if (_challengeIdx >= challengeList.length) {
        phase = GamePhase.finished;
        question = null;
        return;
      }
    }
    question = QuestionFactory.generate(
      mode: mode,
      maxNum: maxNum,
      pLv: pLv,
      fillBothLv: fillBothLv,
      wrongList: wrongList,
      challengeList: challengeList,
      challengeIdx: _challengeIdx,
    );
    if (mode == MathMode.challenge) _challengeIdx++;
  }

  /// モードごとの詳細情報をまとめる（履歴表示用）
  Map<String, dynamic> _buildExtraData(QuestionResult q) {
    switch (mode) {
      case MathMode.clock:
        return {
          'clockHour':     q.clockHour,
          'clockMinute':   q.clockMinute,
          'clockQuestion': q.clockQuestion,
          'clockAnswer':   q.clockAnswer,
        };
      case MathMode.shape:
        return {
          'shapeName':     q.shapeName,
          'shapeQuestion': q.shapeQuestion,
          'shapeAnswer':   q.shapeAnswer,
        };
      case MathMode.shopping:
        return {
          'itemA':    q.shopItemA,
          'itemB':    q.shopItemB,
          'priceA':   q.shopPriceA,
          'priceB':   q.shopPriceB,
          'paid':     q.shopPaid,
          'isChange': q.shopIsChange ? 1 : 0,
        };
      case MathMode.compare:
        return {
          'cmpA': q.cmpA,
          'cmpB': q.cmpB,
        };
      case MathMode.fillBoth:
        return {
          'fillOp':     q.fillOp,
          'fillA':      q.fillA,
          'fillB':      q.fillB,
          'fillAns':    q.fillAns,
          'fillIsLeft': q.fillIsLeft ? 1 : 0,
        };
      case MathMode.tens:
        return {
          'tensBlocks':   q.tensBlocks,
          'tensOnes':     q.tensOnes,
          'tensAskTotal': q.tensAskTotal ? 1 : 0,
        };
      case MathMode.storyPlus:
      case MathMode.storyMinus:
      case MathMode.storyMulti:
      case MathMode.storyDiv:
        return {'story': q.story};
      default:
        return {};
    }
  }

  Future<void> _record(QuestionResult q, bool isCorrect, {String? wrongAnswer}) async {
    await StatsManager.record(mode, isCorrect);
    await CalendarManager.recordQuestion();
    if (!isCorrect) {
      final extra = _buildExtraData(q);
      if (wrongAnswer != null) extra['wrongAnswer'] = wrongAnswer;
      await HistoryManager.recordWrong(
        mode, q.n1, q.n2, q.target,
        extraData: extra,
      );
    }
    final totalSolved = await BadgeManager.totalSolved();
    final stats = await StatsManager.loadAll();
    lastNewBadges = await BadgeManager.checkAndGrant(
      totalSolved: totalSolved,
      streak: streak,
      isPerfect: total == goal && correct == goal,
      isTimeAttack: timeAttack,
      timeAttackScore: correct,
      wrongListCleared: false,
      stats: stats,
    );
  }
}