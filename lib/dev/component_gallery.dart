import 'package:flutter/material.dart';

import '../core/error/app_error.dart';
import '../di/locator.dart';
import '../l10n/app_localizations.dart';
import '../shared/components/app_button.dart';
import '../shared/components/app_error_view.dart';
import '../shared/components/app_text_field.dart';
import '../shared/components/empty_state.dart';
import '../shared/components/loading_view.dart';
import '../shared/services/locale_service.dart';
import '../shared/theme/app_theme.dart';

/// Dev screen: renders every shared component in one place so the theme
/// and components can be eyeballed (light + dark) — currently the app's
/// home until routing lands in Task 8.
///
/// Deliberately does NOT wrap itself in its own MaterialApp: it must run
/// inside the app shell so it inherits the shell's localization and
/// Directionality. It overrides only the theme (via a nested [Theme]) so
/// the dark/light toggle works locally.
class ComponentGallery extends StatefulWidget {
  const ComponentGallery({super.key});

  @override
  State<ComponentGallery> createState() => _ComponentGalleryState();
}

class _ComponentGalleryState extends State<ComponentGallery> {
  var _dark = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _dark ? AppTheme.dark() : AppTheme.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Shared components'),
          actions: [
            TextButton(
              onPressed: sl<LocaleService>().toggle,
              child: Text(AppLocalizations.of(context).switchLanguage),
            ),
            TextButton(
              onPressed: () => setState(() => _dark = !_dark),
              child: Text(_dark ? 'Light' : 'Dark'),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _SectionTitle('Theme'),
            _ThemeCard(),
            _SectionTitle('AppButton'),
            _ButtonCard(),
            _SectionTitle('AppErrorView'),
            _ErrorCard(),
            _SectionTitle('EmptyState'),
            _EmptyCard(),
            _SectionTitle('LoadingView'),
            _LoadingCard(),
            _SectionTitle('AppTextField'),
            _TextFieldCard(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

/// One widget per component, each wrapped in its own Material so
/// Theme.of(context) resolves against the app theme.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Card(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Swatch(label: 'primary', color: scheme.primary),
          _Swatch(label: 'secondary', color: scheme.secondary),
          _Swatch(label: 'error', color: scheme.error),
          _Swatch(label: 'surface', color: scheme.surface),
          _Swatch(label: 'surfaceContainerHighest', color: scheme.surfaceContainerHighest),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _ButtonCard extends StatelessWidget {
  const _ButtonCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppButton(label: 'Primary action', onPressed: _noop),
          const SizedBox(height: 12),
          const AppButton(label: 'With icon', onPressed: _noop, icon: Icons.calendar_today),
          const SizedBox(height: 12),
          const AppButton(label: 'Disabled', onPressed: null),
          const SizedBox(height: 12),
          const AppButton(label: 'Submitting…', onPressed: _noop, loading: true),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          AppErrorView(
            onRetry: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Retry tapped')),
            ),
            error: const NetworkError(message: 'Network connection failed. Please try again.'),
          ),
          const Divider(height: 32),
          const AppErrorView(error: NetworkError(message: 'Network connection failed.')),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: const [
          EmptyState(
            icon: Icons.event_busy,
            title: 'No appointments yet',
            subtitle: 'Book your first visit to get started.',
          ),
          Divider(height: 32),
          EmptyState(icon: Icons.search_off, title: 'No doctors match'),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: const [
          LoadingView(label: 'Loading doctors…'),
          Divider(height: 32),
          LoadingView(),
        ],
      ),
    );
  }
}

class _TextFieldCard extends StatefulWidget {
  const _TextFieldCard();

  @override
  State<_TextFieldCard> createState() => _TextFieldCardState();
}

class _TextFieldCardState extends State<_TextFieldCard> {
  final _email = TextEditingController(text: 'patient@example.com');
  final _password = TextEditingController();
  final _search = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          AppTextField(controller: _email, label: 'Email', hint: 'you@example.com'),
          const SizedBox(height: 16),
          AppTextField(
            controller: _password,
            label: 'Password',
            obscureText: true,
            errorText: 'Password must be at least 8 characters',
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _search,
            label: 'Search',
            hint: 'Search by name or specialty',
            onSubmitted: (_) {},
          ),
        ],
      ),
    );
  }
}

void _noop() {}
