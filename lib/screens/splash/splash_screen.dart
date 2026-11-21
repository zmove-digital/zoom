import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants.dart';

/// Abertura do ZOOM: o logo entra em cena enquanto moedas caem e convergem
/// para dentro dele — uma metáfora visual do dinheiro sendo guardado.
class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.child, super.key});

  /// Tela que aparece depois da animação (onboarding, trava ou app principal).
  final Widget child;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 2900);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  );

  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.04, 0.38, curve: Curves.easeOut),
  );

  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.04, 0.52, curve: Curves.easeOutBack),
  );

  late final Animation<double> _coins = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.16, 0.86, curve: Curves.linear),
  );

  late final Animation<double> _ring = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.18, 0.88, curve: Curves.easeInOutCubic),
  );

  late final Animation<double> _text = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.46, 0.74, curve: Curves.easeOut),
  );

  late final Animation<double> _exit = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.91, 1, curve: Curves.easeIn),
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) _finish();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => widget.child,
        transitionDuration: const Duration(milliseconds: 340),
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Size screen = MediaQuery.of(context).size;
    final double shortest = math.min(screen.width, screen.height);
    final double logoSize = shortest * 0.52;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.12),
                radius: 0.95,
                colors: <Color>[
                  Color(0xFF15483B),
                  Color(0xFF0B1F1B),
                  Color(0xFF080911),
                ],
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 1, end: 0).animate(_exit),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  CustomPaint(
                    size: Size(shortest, shortest),
                    painter: _GlowPainter(_ring.value),
                  ),
                  CustomPaint(
                    size: Size(shortest, shortest),
                    painter: _CoinRainPainter(_coins.value),
                  ),
                  SizedBox(
                    width: logoSize,
                    height: logoSize,
                    child: CustomPaint(
                      painter: _RingPainter(_ring.value),
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Image.asset(
                            'assets/branding/logo_full.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: screen.height * 0.16,
                    child: FadeTransition(
                      opacity: _text,
                      child: Text(
                        AppInfo.tagline,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFFB8F3D8),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Brilho verde suave que cresce junto com o progresso.
class _GlowPainter extends CustomPainter {
  const _GlowPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width * 0.44 * (0.82 + 0.18 * progress);
    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Color.fromRGBO(6, 214, 160, 0.13 + 0.07 * progress),
          const Color(0x0006D6A0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Arco que contorna o logo enquanto o app "guarda" o dinheiro.
class _RingPainter extends CustomPainter {
  const _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x9906D6A0);
    canvas.drawArc(
      rect.deflate(6),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Moedas que caem de cima e convergem para dentro do logo.
class _CoinRainPainter extends CustomPainter {
  const _CoinRainPainter(this.progress);

  static const int _coinCount = 8;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < _coinCount; i++) {
      final double delay = i * 0.052;
      final double p = ((progress - delay) / 0.42).clamp(0.0, 1.0);
      if (p <= 0 || p >= 1) continue;

      final double eased = Curves.easeIn.transform(p);
      final double startX =
          center.dx + math.sin(i * 2.4) * size.width * 0.32;
      final double startY = -40 - (i % 3) * 42;
      final double x = startX + (center.dx - startX) * eased;
      final double y = startY + (center.dy - startY) * eased;
      final double alpha = p > 0.82 ? (1 - p) / 0.18 : 1.0;
      final double radius = 9 + (i % 3) * 2.5;

      _drawCoin(canvas, Offset(x, y), radius, alpha.clamp(0.0, 1.0));
    }
  }

  void _drawCoin(Canvas canvas, Offset center, double radius, double alpha) {
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Color.fromRGBO(255, 198, 66, alpha),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Color.fromRGBO(207, 139, 24, alpha),
    );

    final TextPainter label = TextPainter(
      text: TextSpan(
        text: 'R\$',
        style: TextStyle(
          color: Color.fromRGBO(117, 68, 8, alpha),
          fontSize: radius * 0.92,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(
      canvas,
      center - Offset(label.width / 2, label.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _CoinRainPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
