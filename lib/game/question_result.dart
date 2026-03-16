/// 各ジェネレーターが返す問題データ。
/// UI に必要な情報をすべてここに持たせることで、
/// MathGame 側は QuestionResult を受け取るだけでよい。
class QuestionResult {
  /// 通常問題の数値
  final int n1;
  final int n2;
  final int target;

  /// 選択肢（選択モード用）
  final List<int> choices;

  /// 文章問題のテキスト（空文字なら数式表示）
  final String story;

  /// 絵文字（ヒント表示用）
  final String emoji;

  /// 演算子文字（＋ ー × ÷）
  final String op;

  // ── おかいもの問題 ──
  final int shopPriceA;
  final int shopPriceB;
  final int shopPaid;
  final int shopChange;
  final bool shopIsChange;
  final String shopItemA;
  final String shopItemB;

  // ── 数の大小比較 ──
  final int cmpA;
  final int cmpB;
  final String correctSign;
  final List<String> cmpChoices;

  // ── 虫食い算 ──
  final String fillOp;
  final int fillA;
  final int fillB;
  final int fillAns;
  final bool fillIsLeft;
  final List<int> fillChoices;

  // ── 10のまとまり ──
  final int tensBlocks;
  final int tensOnes;
  final bool tensAskTotal;
  final List<int> tensChoices;

  // ── 時計 ──
  final int clockHour;       // 時
  final int clockMinute;     // 分（0,5,10,15,30,45…）
  final String clockQuestion; // 問題文
  final List<String> clockChoices; // 選択肢文字列
  final String clockAnswer;  // 正解文字列

  // ── 図形 ──
  final String shapeName;      // 'triangle'/'square'/'rectangle'/'circle'/'pentagon'/'hexagon'
  final String shapeQuestion;  // 問題文
  final List<String> shapeChoices;
  final String shapeAnswer;

  // ── 挑戦状 ──
  final String challengeQuestion; // 問題文
  final String challengeFrom;     // 差出人
  final String challengeMessage;  // ひとことメッセージ

  const QuestionResult({
    this.n1 = 0,
    this.n2 = 0,
    this.target = 0,
    this.choices = const [],
    this.story = '',
    this.emoji = '🍓',
    this.op = '＋',
    this.shopPriceA = 0,
    this.shopPriceB = 0,
    this.shopPaid = 0,
    this.shopChange = 0,
    this.shopIsChange = false,
    this.shopItemA = '',
    this.shopItemB = '',
    this.cmpA = 0,
    this.cmpB = 0,
    this.correctSign = '',
    this.cmpChoices = const [],
    this.fillOp = '＋',
    this.fillA = 0,
    this.fillB = 0,
    this.fillAns = 0,
    this.fillIsLeft = true,
    this.fillChoices = const [],
    this.tensBlocks = 0,
    this.tensOnes = 0,
    this.tensAskTotal = true,
    this.tensChoices = const [],
    this.clockHour = 12,
    this.clockMinute = 0,
    this.clockQuestion = '',
    this.clockChoices = const [],
    this.clockAnswer = '',
    this.shapeName = '',
    this.shapeQuestion = '',
    this.shapeChoices = const [],
    this.shapeAnswer = '',
    this.challengeQuestion = '',
    this.challengeFrom = '',
    this.challengeMessage = '',
  });
}
