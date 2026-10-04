import 'package:flutter/material.dart';

class AdaptiveMetrics {
  const AdaptiveMetrics(this.scale);

  static const baseHeight = 360.0;
  static const minimumScale = 0.8;
  static const maximumScale = 1.3;

  final double scale;

  static AdaptiveMetrics fromConstraints(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final heightScale = constraints.maxHeight / baseHeight;
    return AdaptiveMetrics(
      (heightScale / textScale)
          .clamp(minimumScale, maximumScale)
          .toDouble(),
    );
  }

  double size(double baseSize) => baseSize * scale;
}
