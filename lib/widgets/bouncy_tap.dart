import 'package:flutter/material.dart';

/// A drop-in replacement for `Material` + `InkWell` used everywhere a card
/// or button needs to be tappable.
///
/// Why this exists: the app's tappable cards previously used
/// `Material(child: InkWell(onTap: ...))`, and on at least one physical
/// device the tap stopped registering (the ripple/press effect could still
/// show, but `onTap` never fired) even though the callback wiring was
/// correct. `GestureDetector` with `HitTestBehavior.opaque` is a simpler,
/// more predictable hit-testing path than `InkWell`'s ink-splash gesture
/// recognizer, so every tappable surface in the app should go through this
/// widget instead of `InkWell` from now on.
///
/// It also gives every card the same "press down, spring back" candy-style
/// feedback (scale to 95% on press, back to 100% on release) instead of a
/// Material ripple.
class BouncyTap extends StatefulWidget {
  const BouncyTap({
    super.key,
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0.95,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.reverse(),
      onTapCancel: () => _controller.forward(),
      onTapUp: (_) => _controller.forward(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) =>
            Transform.scale(scale: _controller.value, child: child),
        child: widget.child,
      ),
    );
  }
}
