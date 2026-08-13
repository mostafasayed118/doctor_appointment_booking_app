import 'package:flutter/material.dart';

import '../../core/error/app_error.dart';
import '../../l10n/app_localizations.dart';

/// Full-area error state shown by every screen's Error state.
///
/// Renders the error message and, when [onRetry] is provided, a retry
/// button. The retry button is hidden when [onRetry] is null (e.g. for
/// errors where retrying makes no sense).
///
/// This widget only *displays* the error — it never decides what to do.
/// The retry action is delegated up to the caller (usually a Cubit method).
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.error,
    this.onRetry,
  });

  final AppError error;

  /// Called when the user taps retry. When null, no retry button is shown.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              error.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context).retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}