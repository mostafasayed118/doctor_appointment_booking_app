import 'package:flutter/material.dart';

/// Full-area loading indicator used by every screen's Loading state.
///
/// Stateless and dumb on purpose — it just renders a centered spinner with
/// an optional label. Screens embed it inside their own layout.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});

  /// Optional text shown under the spinner, e.g. "Loading doctors…".
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[
            const SizedBox(height: 16),
            Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}