import 'package:flutter/material.dart';

class TextScaleLimit extends StatelessWidget {
  const TextScaleLimit({
    required this.maxScale,
    required this.child,
    super.key,
  });

  final double maxScale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: maxScale),
      ),
      child: child,
    );
  }
}
