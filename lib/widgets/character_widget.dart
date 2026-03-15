import 'package:flutter/material.dart';

enum CharState { normal, correct, wrong, cheer, thinking }

class CharacterWidget extends StatefulWidget {
  final CharState state;
  final double size;
  const CharacterWidget({super.key, this.state = CharState.normal, this.size = 80});
  @override State<CharacterWidget> createState() => _CharacterWidgetState();
}

class _CharacterWidgetState extends State<CharacterWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override void initState() { super.initState(); _ctrl = AnimationController(vsync: this); _anim = Tween<double>(begin: 0, end: 1).animate(_ctrl); _applyAnim(); }
  @override void didUpdateWidget(CharacterWidget old) { super.didUpdateWidget(old); if (old.state != widget.state) _applyAnim(); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  void _applyAnim() {
    _ctrl.stop();
    switch (widget.state) {
      case CharState.correct:  _ctrl.duration = const Duration(milliseconds: 750); _ctrl.repeat();
      case CharState.wrong:    _ctrl.duration = const Duration(milliseconds: 500);  _ctrl.forward(from: 0).then((_) => _ctrl.forward(from: 0));
      case CharState.cheer:    _ctrl.duration = const Duration(milliseconds: 700);  _ctrl.repeat(reverse: true);
      default:                 _ctrl.duration = const Duration(milliseconds: 1800); _ctrl.repeat(reverse: true);
    }
  }

  double _bounceOffset(double t) { if (t < 0.4) return -t/0.4*12; if (t < 0.7) return -12+(t-0.4)/0.3*7; return -5+(t-0.7)/0.3*5; }
  double _shakeAngle(double t)   { final v = t<0.2 ? -t/0.2 : t<0.6 ? -1+(t-0.2)/0.4*2 : 1-(t-0.6)/0.4; return v*8*3.14159/180; }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final r = CustomPaint(size: Size(widget.size, widget.size), painter: _RabbitPainter(state: widget.state));
        return switch (widget.state) {
          CharState.correct => Transform.translate(offset: Offset(0, _bounceOffset(_anim.value)), child: r),
          CharState.wrong   => Transform.rotate(angle: _shakeAngle(_anim.value), child: r),
          CharState.cheer   => Transform.rotate(angle: (_anim.value*2-1)*4*3.14159/180, child: r),
          _                 => Transform.scale(scale: 1.0+_anim.value*0.05, child: r),
        };
      },
    );
  }
}

class _RabbitPainter extends CustomPainter {
  final CharState state;
  const _RabbitPainter({required this.state});

  static const _skin   = Color(0xFFFAE8DC);
  static const _earIn  = Color(0xFFF5B8C8);
  static const _earInW = Color(0xFFE8C0C8);
  static const _cheek  = Color(0xFFF5A0B8);
  static const _cheekW = Color(0xFFDDA0A8);
  static const _line   = Color(0xFF6B3A2A);
  static const _tear   = Color(0xFF99BBEE);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120, size.width / 120);
    final isW = state == CharState.wrong;
    final ei  = isW ? _earInW : _earIn;
    final ch  = isW ? _cheekW : _cheek;
    final f   = Paint()..style = PaintingStyle.fill;
    final lp  = Paint()..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..color = _line;

    // 耳
    void ear(double cx, double cy) {
      f.color = _skin;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx,cy), width:28, height:54), f);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx,cy), width:28, height:54), lp);
      f.color = ei;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx,cy-1), width:17, height:38), f);
    }
    ear(34, 26); ear(86, 26);

    // 顔（横楕円）
    f.color = _skin;
    final fr = Rect.fromCenter(center: const Offset(60,75), width:88, height:80);
    canvas.drawOval(fr, f); canvas.drawOval(fr, lp);

    // ほっぺ
    f.color = ch.withOpacity(0.4);
    canvas.drawOval(Rect.fromCenter(center: const Offset(35,82), width:20, height:14), f);
    canvas.drawOval(Rect.fromCenter(center: const Offset(85,82), width:20, height:14), f);

    // 目
    final ep = Paint()..style=PaintingStyle.stroke..strokeWidth=4..strokeCap=StrokeCap.round..color=_line;
    void arc(double cx, double cy, bool up) {
      final p = Path();
      if (up) { p.moveTo(cx-7,cy+2); p.quadraticBezierTo(cx,cy-7,cx+7,cy+2); }
      else    { p.moveTo(cx-7,cy-2); p.quadraticBezierTo(cx,cy+7,cx+7,cy-2); }
      canvas.drawPath(p, ep);
    }
    switch (state) {
      case CharState.correct:  arc(48,69,true);  arc(72,69,true);
      case CharState.wrong:    arc(48,69,false); arc(72,69,false);
      case CharState.thinking:
        canvas.drawLine(const Offset(42,69),const Offset(54,69),ep);
        canvas.drawLine(const Offset(66,69),const Offset(78,69),ep);
      default:
        f.color=_line;
        canvas.drawCircle(const Offset(48,69),5,f); canvas.drawCircle(const Offset(72,69),5,f);
        f.color=Colors.white;
        canvas.drawCircle(const Offset(50,67),2,f); canvas.drawCircle(const Offset(74,67),2,f);
    }

    // 鼻（横小判）
    f.color = ei;
    final np = Paint()..style=PaintingStyle.stroke..strokeWidth=2..color=_line;
    final nr = Rect.fromCenter(center: const Offset(60,81), width:10, height:7);
    canvas.drawOval(nr,f); canvas.drawOval(nr,np);

    // 口
    final mp = Path();
    switch (state) {
      case CharState.correct:  mp.moveTo(50,89); mp.quadraticBezierTo(60,100,70,89);
      case CharState.wrong:    mp.moveTo(50,97); mp.quadraticBezierTo(60,89,70,97);
      case CharState.thinking: mp.moveTo(51,93); mp.quadraticBezierTo(61,100,70,92);
      default:                 mp.moveTo(50,89); mp.quadraticBezierTo(60,99,70,89);
    }
    canvas.drawPath(mp, lp);

    // 涙
    if (isW) {
      final tp = Paint()..style=PaintingStyle.stroke..strokeWidth=3..strokeCap=StrokeCap.round..color=_tear;
      canvas.drawPath(Path()..moveTo(46,78)..quadraticBezierTo(44,86,43,93), tp);
    }
  }

  @override bool shouldRepaint(_RabbitPainter old) => old.state != state;
}
