import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'default_english_messages.dart';
import 'form_localizations.dart';
import 'form_messages.dart';
import 'spanish_messages.dart';

/// Flutter [LocalizationsDelegate] for integrating `mk_forms` into `MaterialApp.localizationsDelegates`.
class MkFormLocalizationsDelegate
    extends LocalizationsDelegate<MkFormLocalizations> {
  const MkFormLocalizationsDelegate({this.overrides = const {}});

  /// Optional per-app language overrides by language code (e.g. `'fr': MyFrenchMessages()`).
  final Map<String, MkFormMessages> overrides;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MkFormLocalizations> load(Locale locale) {
    // 1. Check custom overrides provided by app
    final custom =
        overrides[locale.languageCode] ??
        overrides['${locale.languageCode}_${locale.countryCode}'];
    if (custom != null) {
      return SynchronousFuture(MkFormLocalizations(custom));
    }

    // 2. Fallback to built-in languages
    final messages = switch (locale.languageCode) {
      'es' => const MkSpanishMessages(),
      _ => const MkDefaultEnglishMessages(),
    };
    return SynchronousFuture(MkFormLocalizations(messages));
  }

  @override
  bool shouldReload(MkFormLocalizationsDelegate old) =>
      !mapEquals(overrides, old.overrides);
}
