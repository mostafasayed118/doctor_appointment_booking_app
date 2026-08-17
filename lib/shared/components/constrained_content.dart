import 'package:flutter/material.dart';

/// Caps a page's content width and centers it, so phone layouts stay
/// readable on tablet/desktop instead of stretching edge-to-edge.
///
/// Constraint-based (no breakpoints): [Center] gives loose constraints and
/// [ConstrainedBox] caps the width, so the child always gets exactly what
/// fits. Pages pick a sensible [maxWidth] per screen — a full list (~900),
/// a profile (~800), or a form (~480).
class ConstrainedContent extends StatelessWidget {
  const ConstrainedContent({
    super.key,
    this.maxWidth = 900,
    required this.child,
  });

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
