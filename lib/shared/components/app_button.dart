import 'package:flutter/material.dart';

/// Primary action button with a built-in loading state.
///
/// When [loading] is true the button is disabled and shows a small spinner
/// instead of its label — this is how we prevent duplicate submissions
/// (e.g. double-tapping "Book appointment").
///
/// Stateless: the caller owns the loading flag (usually from a Cubit state
/// like `BookingSubmitting`), so the button never manages its own state.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? SizedBox(
              width: 20,
              height: 20,
              // Default spinner color is the theme primary, which is the
              // same as the FilledButton background — invisible. Use the
              // button's foreground (contrast) color instead.
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    );
  }
}