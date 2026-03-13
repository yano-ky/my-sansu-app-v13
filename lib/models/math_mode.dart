enum MathMode {
  plus,
  minus,
  multi,
  div,
  storyPlus,
  storyMinus,
  storyMulti,
  storyDiv,
  puzzle,
  wrong,
  shopping,
  compare,
  fillBoth,
  challenge,
  tens;

  bool get isPlus  => this == plus  || this == storyPlus;
  bool get isMinus => this == minus || this == storyMinus;
  bool get isMulti => this == multi || this == storyMulti;
  bool get isDiv   => this == div   || this == storyDiv;

  String get label {
    switch (this) {
      case MathMode.plus:       return 'たしざん';
      case MathMode.minus:      return 'ひきざん';
      case MathMode.multi:      return 'かけざん';
      case MathMode.div:        return 'わりざん';
      case MathMode.storyPlus:  return 'たしざん(ぶんしょう)';
      case MathMode.storyMinus: return 'ひきざん(ぶんしょう)';
      case MathMode.storyMulti: return 'かけざん(ぶんしょう)';
      case MathMode.storyDiv:   return 'わりざん(ぶんしょう)';
      case MathMode.puzzle:     return 'パズル';
      case MathMode.wrong:      return 'にがてこくふく';
      case MathMode.shopping:   return 'おかいもの';
      case MathMode.compare:    return 'かずの おおきさ';
      case MathMode.fillBoth:   return 'むしくいざん';
      case MathMode.challenge:  return 'ちょうせんじょう';
      case MathMode.tens:       return '10の まとまり';
    }
  }

  static MathMode fromString(String s) => MathMode.values.firstWhere(
    (e) => e.name == s,
    orElse: () => MathMode.plus,
  );
}
