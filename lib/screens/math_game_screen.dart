import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/math_mode.dart';
import '../models/managers.dart';
import '../game/question_factory.dart';
import '../game/question_result.dart';
import '../widgets/hint_area.dart';
import '../widgets/character_widget.dart';
import '../models/badge_manager.dart';

class MathGame extends StatefulWidget {
  final MathMode mode;
  final int maxNum, goal;
  final bool isSelect;
  final int pLv;
  final int fillBothLv;
  final bool timeAttack;

  const MathGame({
    super.key,
    required this.mode,
    required this.maxNum,
    required this.goal,
    required this.isSelect,
    this.pLv = 1,
    this.fillBothLv = 0,
    this.timeAttack = false,
  });

  @override
  State<MathGame> createState() => _MathGameState();
}

class _MathGameState extends State<MathGame> {
  late MathMode curM;
  late QuestionResult q;

  // パズル用スロット
  List<int?> slots = [];

  int curQ = 1;
  bool showTable = false;
  int hintLevel = 0;
  int correctCount = 0, wrongCount = 0;
  int streak = 0;
  List<dynamic> wList = [];
  bool _showCharacter = true;
  CharState _charState = CharState.normal;
  String _wrongAdvice = '';

  // 挑戦状
  List<Map<String, dynamic>> _challengeList = [];
  int _challengeIdx = 0;

  // タイムアタック
  int _timeLeft = 30;
  bool _timerRunning = false;

  final TextEditingController _ansCtrl = TextEditingController();

  @override
  void dispose() {
    _ansCtrl.dispose();
    _stopTimer();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    curM = widget.mode;
    _loadCharacterSetting();
    if (curM == MathMode.wrong)          _loadWrongList();
    else if (curM == MathMode.challenge) _loadChallengeList();
    else {
      _generateQuestion();
      if (widget.timeAttack) _startTimer();
    }
  }

  Future<void> _loadCharacterSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _showCharacter = prefs.getBool('showCharacter') ?? true);
  }

  // ── データロード ──────────────────────────────────────────────────

  Future<void> _loadWrongList() async {
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> parsed = [];
    try {
      final d = prefs.getString('wrongList');
      if (d != null) parsed = json.decode(d);
    } catch (_) {}
    if (!mounted) return;
    setState(() { wList = parsed; });
    if (wList.isEmpty) { Navigator.pop(context); return; }
    _generateQuestion();
    if (widget.timeAttack) _startTimer();
  }

  Future<void> _loadChallengeList() async {
    final list = await ChallengeManager.loadAll();
    if (!mounted) return;
    if (list.isEmpty) { Navigator.pop(context); return; }
    setState(() { _challengeList = list; _challengeIdx = 0; });
    _generateQuestion();
    if (widget.timeAttack) _startTimer();
  }

  // ── タイマー ─────────────────────────────────────────────────────

  void _startTimer() {
    _timeLeft = 30;
    _timerRunning = true;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_timerRunning) return false;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) { _timerRunning = false; _finishGame(); return false; }
      return true;
    });
  }

  void _stopTimer() { _timerRunning = false; }

  // ── 問題生成 ─────────────────────────────────────────────────────

  void _generateQuestion() {
    showTable = false;
    hintLevel = 0;
    _ansCtrl.clear();
    if (mounted) setState(() => _charState = CharState.normal);

    // パズルのスロットリセット
    if (curM == MathMode.puzzle) {
      slots = List.filled(widget.pLv == 3 ? 3 : 2, null);
    }

    setState(() {
      q = QuestionFactory.generate(
        mode: curM,
        maxNum: widget.maxNum,
        pLv: widget.pLv,
        fillBothLv: widget.fillBothLv,
        wrongList: wList,
        challengeList: _challengeList,
        challengeIdx: _challengeIdx,
      );
    });
  }

  // ── 回答チェック ─────────────────────────────────────────────────

  Future<void> _checkAnswer(bool ok) async {
    await StatsManager.record(curM, ok);
    await CalendarManager.recordQuestion();

    if (ok) { correctCount++; streak++; setState(() { _charState = CharState.correct; _wrongAdvice = ''; }); }
    else    { wrongCount++;   streak = 0; setState(() { _charState = CharState.wrong; _wrongAdvice = AdviceManager.wrongAdvice(curM); }); }

    final prefs = await SharedPreferences.getInstance();
    List<dynamic> list = [];
    try { list = json.decode(prefs.getString('wrongList') ?? '[]'); } catch (_) {}

    if (ok) {
      if (widget.mode == MathMode.wrong) {
        if (list.isNotEmpty) list.removeAt(0);
        await prefs.setString('wrongList', json.encode(list));
        setState(() { if (wList.isNotEmpty) wList.removeAt(0); });
      }
    } else if (widget.mode != MathMode.wrong) {
      final saveN1 = (curM == MathMode.fillBoth) ? q.fillA
                   : (curM == MathMode.compare)  ? q.cmpA
                   : (curM == MathMode.shopping) ? q.shopPriceA
                   : q.n1;
      final saveN2 = (curM == MathMode.fillBoth) ? q.fillB
                   : (curM == MathMode.compare)  ? q.cmpB
                   : (curM == MathMode.shopping) ? q.shopPriceB
                   : q.n2;
      final canSave = curM != MathMode.challenge && curM != MathMode.tens;
      if (canSave) {
        final exists = (curM == MathMode.shopping)
            ? list.any((e) => e['m'] == curM.name && e['t'] == q.target && e['paid'] == q.shopPaid)
            : list.any((e) => e['m'] == curM.name && e['n1'] == saveN1 && e['n2'] == saveN2);
        if (!exists) {
          final entry = <String, dynamic>{
            'm': curM.name, 'n1': saveN1, 'n2': saveN2, 't': q.target,
          };
          if (curM == MathMode.fillBoth) {
            entry['op']     = q.fillOp;
            entry['isLeft'] = q.fillIsLeft ? 1 : 0;
          }
          if (curM == MathMode.shopping) {
            entry['paid']     = q.shopPaid;
            entry['isChange'] = q.shopIsChange ? 1 : 0;
            entry['priceA']   = q.shopPriceA;
            entry['priceB']   = q.shopPriceB;
            entry['itemA']    = q.shopItemA;
            entry['itemB']    = q.shopItemB;
          }
          list.add(entry);
          await prefs.setString('wrongList', json.encode(list));
        }
        await HistoryManager.recordWrong(curM, saveN1, saveN2, q.target);
      }
    }

    _showResultDialog(ok);
  }

  void _showResultDialog(bool ok) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) {
        if (ok) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted && Navigator.canPop(c)) {
              Navigator.pop(c);
              _onCorrect();
            }
          });
        } else {
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted && Navigator.canPop(c)) Navigator.pop(c);
          });
        }
        return AlertDialog(
          backgroundColor: ok ? Colors.orange : Colors.blueGrey,
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              ok ? '✨ せいかい！ ✨' : '❌ おしい！',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
          content: ok && streak >= 3
              ? Text('🔥 $streak かいつづいてるよ！',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))
              : !ok && _wrongAdvice.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('🐰 $_wrongAdvice',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14, height: 1.5)),
                    )
                  : null,
          actions: ok
              ? null
              : [Center(child: TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('もういちど',
                      style: TextStyle(color: Colors.white))))],
        );
      },
    );
  }

  void _onCorrect() {
    if (widget.mode == MathMode.wrong) {
      if (wList.isEmpty) _finishGame(); else _generateQuestion();
    } else if (curM == MathMode.challenge) {
      _challengeIdx++;
      if (_challengeIdx >= _challengeList.length) _finishGame();
      else _generateQuestion();
    } else if (!widget.timeAttack) {
      curQ++;
      if (curQ > widget.goal) _finishGame(); else _generateQuestion();
    } else {
      _generateQuestion();
    }
  }

  void _finishGame() async {
    _stopTimer();
    final total    = correctCount + wrongCount;
    final pct      = total == 0 ? 0 : (correctCount * 100 / total).round();
    final isPerfect = pct == 100 && total > 0;
    final advice   = AdviceManager.resultAdvice(pct, streak);
    String medal;
    if (pct == 100)     medal = '🥇';
    else if (pct >= 80) medal = '🥈';
    else if (pct >= 50) medal = '🥉';
    else                medal = '⭐';

    // バッジ判定
    final stats        = await StatsManager.loadAll();
    final solved       = await BadgeManager.totalSolved();
    final wrongCleared = widget.mode == MathMode.wrong && wList.isEmpty;
    final newBadges    = await BadgeManager.checkAndGrant(
      totalSolved:      solved,
      streak:           streak,
      isPerfect:        isPerfect,
      isTimeAttack:     widget.timeAttack,
      timeAttackScore:  widget.timeAttack ? correctCount : 0,
      wrongListCleared: wrongCleared,
      stats:            stats,
    );

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Center(child: Text(
          widget.timeAttack ? '⏱️ タイムアップ！' : '🎊 おわったよ！ 🎊',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        )),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(medal, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 8),
          // キャラアドバイス
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(children: [
              const Text('🐰', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(child: Text(advice,
                  style: const TextStyle(fontSize: 14, height: 1.5))),
            ]),
          ),
          if (widget.timeAttack) ...[
            const SizedBox(height: 10),
            Text('30びょうで $correctCount もん せいかい！',
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _resultItem('✅ せいかい', correctCount, Colors.green),
                Container(width: 1, height: 44, color: Colors.orange.shade200),
                _resultItem('❌ ふせいかい', wrongCount, Colors.red),
              ]),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Colors.orange.shade200, height: 1),
              ),
              _resultItem('📊 せいかいりつ', pct, Colors.blue, suffix: '%'),
            ]),
          ),
          // 新バッジ獲得
          if (newBadges.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(children: [
                const Text('🏅 あたらしい バッジ！',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: newBadges.map((id) {
                    final b = BadgeManager.defById(id);
                    if (b == null) return const SizedBox.shrink();
                    return Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(b.emoji, style: const TextStyle(fontSize: 28)),
                      Text(b.title,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold)),
                    ]);
                  }).toList(),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 20),
        ])),
        actions: [
          Center(child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () { Navigator.pop(c); Navigator.pop(context); },
            child: const Text('もどる', style: TextStyle(fontSize: 16)),
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _resultItem(String label, int value, Color color, {String suffix = 'もん'}) =>
      Column(children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text('$value$suffix',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      ]);

  // ── build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final titleText = widget.timeAttack
        ? '⏱️ ${'$_timeLeft'.padLeft(2, '0')} びょう　$correctCount もん'
        : widget.mode == MathMode.wrong
            ? '🔥 にがてを こくふく\n(のこり ${wList.length} もん)'
            : widget.mode == MathMode.challenge &&
                    _challengeList.isNotEmpty &&
                    _challengeIdx < _challengeList.length
                ? '📝 ${_challengeList[_challengeIdx]['from'] ?? 'ちょうせんじょう'} からの ちょうせん！'
                : 'だい $curQ もん / ${widget.goal} もん';

    final progress = widget.timeAttack
        ? _timeLeft / 30
        : widget.mode == MathMode.wrong
            ? 0.0
            : (curQ - 1) / widget.goal;

    final timerColor = _timeLeft <= 10 ? Colors.red : Colors.orange;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: widget.timeAttack && _timeLeft <= 10
            ? Colors.red.shade200
            : Colors.orange.shade200,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(titleText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, height: 1.2)),
        ),
        actions: _showCharacter
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CharacterWidget(state: _charState, size: 48),
                )
              ]
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.orange.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(
                widget.timeAttack ? timerColor : Colors.orange),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(children: [
              if (curM == MathMode.puzzle)         _buildPuzzleUI()
              else if (curM == MathMode.shopping)  _buildShoppingUI()
              else if (curM == MathMode.compare)   _buildCompareUI()
              else if (curM == MathMode.fillBoth)  _buildFillBothUI()
              else if (curM == MathMode.tens)      _buildTensUI()
              else if (curM == MathMode.challenge) _buildChallengeUI()
              else if (curM == MathMode.clock)     _buildClockUI()
              else if (curM == MathMode.shape)     _buildShapeUI()
              else                                 _buildNormalUI(),
              if (curM.isMulti) ...[
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => setState(() => showTable = !showTable),
                  icon: Icon(showTable ? Icons.visibility_off : Icons.visibility),
                  label: const Text('かけざん はやみひょう'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade100),
                ),
                if (showTable) _buildMultiTable(),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  // ── 通常問題UI ────────────────────────────────────────────────────

  Widget _buildNormalUI() => Column(children: [
    const SizedBox(height: 30),
    q.story.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(q.story,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
              ),
            ))
        : Text('${q.n1} ${q.op} ${q.n2} ＝ ?',
            style: const TextStyle(fontSize: 55, fontWeight: FontWeight.bold)),
    const SizedBox(height: 30),
    widget.isSelect ? _buildChoiceGrid(q.choices) : _buildInputField(),
    const SizedBox(height: 20),
    _buildHintButtons(),
    if (hintLevel > 0)
      HintArea(
        hintLevel: hintLevel,
        op: q.op,
        n1: q.n1, n2: q.n2, target: q.target,
        emoji: q.emoji,
      ),
  ]);

  Widget _buildChoiceGrid(List<int> choices) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    mainAxisSpacing: 15,
    crossAxisSpacing: 15,
    padding: const EdgeInsets.symmetric(horizontal: 40),
    childAspectRatio: 1.8,
    children: choices.map((c) => ElevatedButton(
      style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      onPressed: () => _checkAnswer(c == q.target),
      child: Text('$c',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
    )).toList(),
  );

  Widget _buildInputField({VoidCallback? onSubmit}) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: TextField(
        controller: _ansCtrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 38),
        onSubmitted: (_) =>
            _checkAnswer(int.tryParse(_ansCtrl.text) == q.target),
      ),
    ),
    const SizedBox(height: 12),
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: () =>
          _checkAnswer(int.tryParse(_ansCtrl.text) == q.target),
      child: const Text('こたえあわせ！',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    ),
  ]);

  Widget _buildHintButtons() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    if (hintLevel == 0)
      TextButton.icon(
        onPressed: () => setState(() => hintLevel = 1),
        icon: const Icon(Icons.lightbulb_outline),
        label: const Text('ヒント①'),
      ),
    if (hintLevel == 1) ...[
      TextButton.icon(
        onPressed: () => setState(() => hintLevel = 0),
        icon: const Icon(Icons.lightbulb, color: Colors.amber),
        label: const Text('ヒントをかくす'),
      ),
      const SizedBox(width: 8),
      TextButton.icon(
        onPressed: () => setState(() => hintLevel = 2),
        icon: const Icon(Icons.lightbulb, color: Colors.orange),
        label: const Text('ヒント②'),
      ),
    ],
    if (hintLevel == 2)
      TextButton.icon(
        onPressed: () => setState(() => hintLevel = 0),
        icon: const Icon(Icons.lightbulb, color: Colors.orange),
        label: const Text('ヒントをかくす'),
      ),
  ]);

  // ── おかいもの問題UI ───────────────────────────────────────────────

  Widget _buildShoppingUI() => Column(children: [
    const SizedBox(height: 20),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 4,
        color: Colors.pink.shade50,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const Text('🛒 おみせやさん',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _shopItem(q.shopItemA, q.shopPriceA),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('＋',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ),
              _shopItem(q.shopItemB, q.shopPriceB),
            ]),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.pink.shade200),
              ),
              child: Text(
                q.shopIsChange
                    ? '💰 ${q.shopPaid}えん だしたら\nおつりは なんえん？'
                    : 'ぜんぶで なんえん？',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, height: 1.6),
              ),
            ),
          ]),
        ),
      ),
    ),
    const SizedBox(height: 24),
    widget.isSelect ? _buildChoiceGrid(q.choices) : _buildInputField(),
    const SizedBox(height: 20),
  ]);

  Widget _shopItem(String name, int price) => Column(children: [
    Text(name, style: const TextStyle(fontSize: 28)),
    const SizedBox(height: 4),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.pink.shade300),
      ),
      child: Text('${price}えん',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.pink.shade700)),
    ),
  ]);

  // ── 数の大小比較UI ─────────────────────────────────────────────────

  Widget _buildCompareUI() => Column(children: [
    const SizedBox(height: 40),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _cmpBox('${q.cmpA}', Colors.cyan.shade100, Colors.cyan.shade300),
      const SizedBox(width: 12),
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
            child: Text('？', style: TextStyle(fontSize: 26, color: Colors.grey))),
      ),
      const SizedBox(width: 12),
      _cmpBox('${q.cmpB}', Colors.orange.shade100, Colors.orange.shade300),
    ]),
    const SizedBox(height: 12),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(width: 80, child: Center(child: Text('ひだり',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)))),
      const SizedBox(width: 76),
      SizedBox(width: 80, child: Center(child: Text('みぎ',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)))),
    ]),
    const SizedBox(height: 32),
    Column(children: q.cmpChoices.map((sign) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: sign == '＞' ? Colors.red.shade50 : Colors.blue.shade50,
            foregroundColor: Colors.black87,
            side: BorderSide(
                color: sign == '＞' ? Colors.red.shade300 : Colors.blue.shade300,
                width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
          onPressed: () => _checkAnswer(sign == q.correctSign),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              children: [
                TextSpan(text: '${q.cmpA} ',
                    style: TextStyle(color: Colors.cyan.shade700)),
                TextSpan(text: sign,
                    style: const TextStyle(fontSize: 28, color: Colors.black)),
                TextSpan(text: ' ${q.cmpB}',
                    style: TextStyle(color: Colors.orange.shade700)),
              ],
            ),
          ),
        ),
      ),
    )).toList()),
    const SizedBox(height: 30),
  ]);

  Widget _cmpBox(String val, Color bg, Color border) => Container(
    width: 80, height: 80,
    decoration: BoxDecoration(
      color: bg, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: border, width: 2),
    ),
    child: Center(child: Text(val,
        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold))),
  );

  // ── 虫食い算UI ────────────────────────────────────────────────────

  Widget _buildFillBothUI() {
    final leftStr  = q.fillIsLeft  ? '□' : '${q.fillA}';
    final rightStr = !q.fillIsLeft ? '□' : '${q.fillB}';
    final result = switch (q.fillOp) {
      '＋' => q.fillA + q.fillB,
      '－' => q.fillA - q.fillB,
      '×' => q.fillA * q.fillB,
      _   => (q.fillA / q.fillB).round(),
    };

    return Column(children: [
      const SizedBox(height: 30),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.lime.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.lime.shade400, width: 2),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _fillBox(leftStr),
          Text(' ${q.fillOp} ',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          _fillBox(rightStr),
          const Text(' ＝ ',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          Text('$result',
              style: const TextStyle(
                  fontSize: 40, fontWeight: FontWeight.bold, color: Colors.red)),
        ]),
      ),
      const SizedBox(height: 10),
      Text('□ に はいる かずは？',
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
      const SizedBox(height: 24),
      widget.isSelect
          ? GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              childAspectRatio: 1.8,
              children: q.fillChoices.map((c) => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lime.shade100,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () => _checkAnswer(c == q.target),
                child: Text('$c',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold)),
              )).toList())
          : _buildInputField(),
      const SizedBox(height: 20),
    ]);
  }

  Widget _fillBox(String val) {
    final isBlank = val == '□';
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        color: isBlank ? Colors.orange.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBlank ? Colors.orange.shade400 : Colors.grey.shade300,
          width: isBlank ? 2.5 : 1,
        ),
      ),
      child: Center(child: Text(val,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isBlank ? Colors.orange.shade700 : Colors.black87,
          ))),
    );
  }

  // ── 10のまとまりUI ───────────────────────────────────────────────

  Widget _buildTensUI() {
    final question = q.tensAskTotal
        ? '10の まとまりが ${q.tensBlocks} こ、バラが ${q.tensOnes} こ。\nぜんぶで いくつ？'
        : '${q.tensBlocks * 10 + q.tensOnes} は、10の まとまりが いくつ と バラが ${q.tensOnes} こ？';

    return Column(children: [
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          color: Colors.teal.shade50,
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Text(question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.bold, height: 1.7)),
              const SizedBox(height: 16),
              Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center,
                  children: [
                    ...List.generate(q.tensBlocks, (i) => Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade400,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade700),
                      ),
                      child: const Center(child: Text('10',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white))),
                    )),
                    ...List.generate(q.tensOnes, (i) => Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: Colors.cyan.shade300,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.cyan.shade600),
                      ),
                      child: Center(child: Text('1',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyan.shade900))),
                    )),
                  ]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _tensLegend(Colors.amber.shade400, '10のまとまり ×${q.tensBlocks}'),
                const SizedBox(width: 12),
                if (q.tensOnes > 0)
                  _tensLegend(Colors.cyan.shade300, 'バラ ×${q.tensOnes}'),
              ]),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 20),
      _buildChoiceGrid(q.tensChoices),
      const SizedBox(height: 16),
    ]);
  }

  Widget _tensLegend(Color color, String label) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 14, height: 14,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]);

  // ── 挑戦状UI ─────────────────────────────────────────────────────

  Widget _buildChallengeUI() {
    if (_challengeList.isEmpty || _challengeIdx >= _challengeList.length) {
      return const SizedBox();
    }
    final item     = _challengeList[_challengeIdx];
    final from     = item['from']     as String? ?? 'パパ・ママ';
    final message  = item['message']  as String? ?? '';
    final question = item['question'] as String? ?? '';

    return Column(children: [
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.deepOrange.shade200),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('📝 ', style: TextStyle(fontSize: 18)),
              Text('$from からの ちょうせんじょう！',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange.shade700)),
              const Spacer(),
              Text('${_challengeIdx + 1} / ${_challengeList.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ]),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('💬 $message',
                    style: const TextStyle(
                        fontSize: 14, fontStyle: FontStyle.italic, height: 1.5)),
              ),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(question,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, height: 1.7),
                textAlign: TextAlign.center),
          ),
        ),
      ),
      const SizedBox(height: 24),
      widget.isSelect ? _buildChoiceGrid(q.choices) : _buildInputField(),
      const SizedBox(height: 20),
    ]);
  }

  // ── パズルUI ──────────────────────────────────────────────────────

  Widget _buildPuzzleUI() {
    final isDivSelect = q.op == '÷' && widget.isSelect;
    if (isDivSelect) {
      return Column(children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            color: Colors.yellow.shade100, elevation: 2,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text('こたえを えらんでね！',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('${q.n1} ${q.op} ${q.n2} ＝ ?',
            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildChoiceGrid(q.choices),
      ]);
    }

    String ruleText;
    if (widget.pLv == 3) {
      ruleText = '3つの □ に すうじを いれて\nあわせると あかいかずに なるように しよう！';
    } else if (q.op == '÷') {
      ruleText = '□ ${q.op} □ ＝ あかいかず に なるように\n2つの □ に すうじを いれよう！\n（わりきれる かずを さがそう）';
    } else {
      ruleText = '□ ${q.op} □ ＝ あかいかず に なるように\n2つの □ に すうじを いれよう！';
    }

    return Column(children: [
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Card(
          color: Colors.yellow.shade100, elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(ruleText,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, height: 1.6)),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text('${q.target}',
          style: const TextStyle(
              fontSize: 60, color: Colors.red, fontWeight: FontWeight.bold)),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _puzzleSlot(0),
        Text(q.op, style: const TextStyle(fontSize: 28)),
        _puzzleSlot(1),
        if (widget.pLv == 3) ...[
          const Text(' ＋ ', style: TextStyle(fontSize: 28)),
          _puzzleSlot(2),
        ],
      ]),
      const SizedBox(height: 25),
      Wrap(
        spacing: 8, runSpacing: 8,
        alignment: WrapAlignment.center,
        children: List.generate(21, (i) => ElevatedButton(
          onPressed: () {
            setState(() {
              final idx = slots.indexOf(null);
              if (idx != -1) slots[idx] = i;
            });
            if (!slots.contains(null)) {
              double res = 0;
              if (q.op == '＋')      res = (slots[0]! + slots[1]!).toDouble();
              else if (q.op == '－') res = (slots[0]! - slots[1]!).toDouble();
              else if (q.op == '×') res = (slots[0]! * slots[1]!).toDouble();
              else if (q.op == '÷') {
                if (slots[1] == 0) {
                  setState(() => slots = List.filled(slots.length, null));
                  return;
                }
                res = slots[0]! / slots[1]!;
              }
              if (widget.pLv == 3) {
                res = (slots[0]! + slots[1]! + slots[2]!).toDouble();
              }
              _checkAnswer(res == q.target.toDouble());
            }
          },
          child: Text('$i'),
        )),
      ),
      TextButton(
        onPressed: () =>
            setState(() => slots = List.filled(slots.length, null)),
        child: const Text('やりなおす'),
      ),
    ]);
  }

  Widget _puzzleSlot(int i) => Container(
    width: 50, height: 50,
    margin: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.orange),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Center(child: Text(
      slots.length > i ? (slots[i]?.toString() ?? '?') : '?',
      style: const TextStyle(fontSize: 24),
    )),
  );

  // ── かけざん早見表 ────────────────────────────────────────────────

  Widget _buildMultiTable() => Card(
    elevation: 0, color: Colors.white, margin: const EdgeInsets.all(15),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade200, width: 0.5),
        children: List.generate(10, (r) => TableRow(
          children: List.generate(10, (c) {
            if (r == 0 && c == 0) {
              return const Center(
                  child: Text('×', style: TextStyle(fontSize: 14, color: Colors.grey)));
            }
            if (r == 0 || c == 0) {
              return Container(
                height: 35, color: Colors.orange.shade50,
                child: Center(child: Text('${r == 0 ? c : r}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))));
            }
            final active = (r == q.n1 && c == q.n2);
            return Container(
              height: 35,
              color: active ? Colors.purple.shade200 : Colors.white,
              child: Center(child: Text('${r * c}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800))));
          }),
        )),
      ),
    ),
  );

  // ── 時計UI ───────────────────────────────────────────────────────

  Widget _buildClockUI() => Column(children: [
    const SizedBox(height: 20),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 3,
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Text(q.clockQuestion,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // アナログ時計
            CustomPaint(
              size: const Size(180, 180),
              painter: _ClockPainter(hour: q.clockHour, minute: q.clockMinute),
            ),
            const SizedBox(height: 12),
            // デジタル表示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                '${q.clockHour} : ${q.clockMinute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ]),
        ),
      ),
    ),
    const SizedBox(height: 20),
    // 選択肢
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: q.clockChoices.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.blue.shade200),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 1,
              ),
              onPressed: () => _checkAnswer(c == q.clockAnswer),
              child: Text(c,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        )).toList(),
      ),
    ),
    const SizedBox(height: 16),
  ]);

  // ── 図形UI ───────────────────────────────────────────────────────

  Widget _buildShapeUI() => Column(children: [
    const SizedBox(height: 20),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 3,
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Text(q.shapeQuestion,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            CustomPaint(
              size: const Size(160, 140),
              painter: _ShapePainter(shapeName: q.shapeName),
            ),
          ]),
        ),
      ),
    ),
    const SizedBox(height: 20),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.2,
        children: q.shapeChoices.map((c) => ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade50,
            foregroundColor: Colors.black87,
            side: BorderSide(color: Colors.green.shade300),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _checkAnswer(c == q.shapeAnswer),
          child: Text(c,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold)),
        )).toList(),
      ),
    ),
    const SizedBox(height: 20),
  ]);
}

// ── 時計 CustomPainter ────────────────────────────────────────────────
class _ClockPainter extends CustomPainter {
  final int hour, minute;
  const _ClockPainter({required this.hour, required this.minute});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r  = size.width / 2 - 8;

    final bg = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final rim = Paint()..color = const Color(0xFF3A6EA5)..style = PaintingStyle.stroke..strokeWidth = 6;
    final tick = Paint()..color = Colors.grey.shade400..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    final bigTick = Paint()..color = Colors.grey.shade600..strokeWidth = 3..strokeCap = StrokeCap.round;
    final hourHand = Paint()..color = const Color(0xFF3A3A3A)..strokeWidth = 6..strokeCap = StrokeCap.round;
    final minHand  = Paint()..color = const Color(0xFF3A6EA5)..strokeWidth = 4..strokeCap = StrokeCap.round;
    final center   = Paint()..color = const Color(0xFF3A3A3A)..style = PaintingStyle.fill;

    // 文字盤
    canvas.drawCircle(Offset(cx, cy), r, bg);
    canvas.drawCircle(Offset(cx, cy), r, rim);

    // 目盛り
    for (int i = 0; i < 60; i++) {
      final angle = i * 6 * 3.14159 / 180 - 3.14159 / 2;
      final isHour = i % 5 == 0;
      final len = isHour ? 10.0 : 5.0;
      final p = isHour ? bigTick : tick;
      canvas.drawLine(
        Offset(cx + (r - len) * cos(angle), cy + (r - len) * sin(angle)),
        Offset(cx + r * cos(angle),          cy + r * sin(angle)),
        p,
      );
    }

    // 数字（12,3,6,9）
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final n in [12, 3, 6, 9]) {
      final angle = (n * 30 - 90) * 3.14159 / 180;
      final tx = cx + (r - 22) * cos(angle);
      final ty = cy + (r - 22) * sin(angle);
      tp.text = TextSpan(
        text: '$n',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(tx - tp.width / 2, ty - tp.height / 2));
    }

    // 時針
    final hAngle = ((hour % 12) + minute / 60) * 30 * 3.14159 / 180 - 3.14159 / 2;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.52 * cos(hAngle), cy + r * 0.52 * sin(hAngle)),
      hourHand,
    );

    // 分針
    final mAngle = minute * 6 * 3.14159 / 180 - 3.14159 / 2;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.78 * cos(mAngle), cy + r * 0.78 * sin(mAngle)),
      minHand,
    );

    // 中心点
    canvas.drawCircle(Offset(cx, cy), 6, center);
    canvas.drawCircle(Offset(cx, cy), 3, Paint()..color = Colors.white);
  }

  @override bool shouldRepaint(_ClockPainter old) =>
      old.hour != hour || old.minute != minute;
}

// ── 図形 CustomPainter ────────────────────────────────────────────────
class _ShapePainter extends CustomPainter {
  final String shapeName;
  const _ShapePainter({required this.shapeName});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final fill   = Paint()..color = const Color(0xFFB8E6C8)..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round;

    switch (shapeName) {
      case 'triangle':
        final path = Path()
          ..moveTo(cx, cy - 55)
          ..lineTo(cx + 60, cy + 45)
          ..lineTo(cx - 60, cy + 45)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      case 'square':
        final r = Rect.fromCenter(center: Offset(cx, cy), width: 110, height: 110);
        canvas.drawRect(r, fill);
        canvas.drawRect(r, stroke);
      case 'rectangle':
        final r = Rect.fromCenter(center: Offset(cx, cy), width: 140, height: 90);
        canvas.drawRect(r, fill);
        canvas.drawRect(r, stroke);
      case 'circle':
        canvas.drawCircle(Offset(cx, cy), 58, fill);
        canvas.drawCircle(Offset(cx, cy), 58, stroke);
      case 'pentagon':
        canvas.drawPath(_polygon(cx, cy, 55, 5, -90), fill);
        canvas.drawPath(_polygon(cx, cy, 55, 5, -90), stroke);
      case 'hexagon':
        canvas.drawPath(_polygon(cx, cy, 58, 6, 0), fill);
        canvas.drawPath(_polygon(cx, cy, 58, 6, 0), stroke);
    }
  }

  Path _polygon(double cx, double cy, double r, int sides, double startDeg) {
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = (startDeg + i * 360 / sides) * 3.14159 / 180;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    return path..close();
  }

  @override bool shouldRepaint(_ShapePainter old) => old.shapeName != shapeName;
}
