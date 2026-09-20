import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../core/di/injection.dart';
import 'bloc/i18n_demo_form_bloc.dart';

/// Screen demonstrating dynamic i18n, localized error messages,
/// and per-app message overrides powered by [I18nDemoFormBloc].
@RoutePage()
class I18nDemoScreen extends StatefulWidget {
  const I18nDemoScreen({super.key, I18nDemoFormBloc? formBloc})
    : _formBloc = formBloc;

  final I18nDemoFormBloc? _formBloc;

  @override
  State<I18nDemoScreen> createState() => _I18nDemoScreenState();
}

class _I18nDemoScreenState extends State<I18nDemoScreen> {
  late final I18nDemoFormBloc _formBloc;
  Locale _currentLocale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _formBloc = widget._formBloc ?? getIt<I18nDemoFormBloc>();
  }

  @override
  void dispose() {
    unawaited(_formBloc.close());
    super.dispose();
  }

  void _toggleLocale() {
    setState(() {
      _currentLocale = _currentLocale.languageCode == 'en'
          ? const Locale('es')
          : const Locale('en');
    });
  }

  @override
  Widget build(BuildContext context) {
    // We wrap this screen's subtree with Localizations.override to demonstrate
    // dynamic runtime locale switching seamlessly.
    return Localizations.override(
      context: context,
      locale: _currentLocale,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Internationalization (i18n)'),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.language),
              label: Text(
                _currentLocale.languageCode == 'en' ? 'English' : 'Español',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: _toggleLocale,
            ),
          ],
        ),
        body: MkFormScope.value(
          value: _formBloc,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dynamic Language Switching (No UI Jank)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onTertiaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '1. Submit or touch fields below with empty/invalid inputs to see errors.\n'
                          '2. Tap the language button in the top right (EN/ES).\n'
                          '3. Watch errors instantly update between English and Spanish.\n'
                          '4. Fully compatible with flutter_localizations and per-app custom overrides.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const MkTextField(
                  name: 'username',
                  decoration: InputDecoration(
                    labelText: 'Username (min 5 chars)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                const MkEmailField(name: 'email'),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _formBloc.submit(),
                  child: Text(
                    _currentLocale.languageCode == 'en'
                        ? 'Validate & Submit'
                        : 'Validar y Enviar',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _formBloc.reset(),
                  child: Text(
                    _currentLocale.languageCode == 'en'
                        ? 'Reset'
                        : 'Restablecer',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
