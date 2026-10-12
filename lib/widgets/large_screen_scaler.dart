import 'dart:math' as math;

import 'package:flutter/material.dart';

class LargeScreenScaler extends StatelessWidget {
  const LargeScreenScaler({required this.child, super.key});

  static const baseWidth = 640.0;
  static const baseHeight = 400.0;
  static const maxScale = 3.0;

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final scale = math
              .min(width / baseWidth, height / baseHeight)
              .clamp(1.0, maxScale)
              .toDouble();
          if (scale <= 1.01) return child;

          final logicalSize = Size(width / scale, height / scale);
          final mediaQuery = MediaQuery.of(context);
          return SizedBox.expand(
            child: FittedBox(
              key: const ValueKey('large-screen-scaler-stage'),
              fit: BoxFit.fill,
              child: SizedBox(
                width: logicalSize.width,
                height: logicalSize.height,
                child: MediaQuery(
                  data: mediaQuery.copyWith(
                    size: logicalSize,
                    padding: mediaQuery.padding / scale,
                    viewPadding: mediaQuery.viewPadding / scale,
                    viewInsets: mediaQuery.viewInsets / scale,
                    systemGestureInsets:
                        mediaQuery.systemGestureInsets / scale,
                  ),
                  child: child,
                ),
              ),
            ),
          );
        },
      );
}
