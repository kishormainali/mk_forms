import 'package:flutter/widgets.dart';
import 'default_english_messages.dart';
import 'form_messages.dart';
import 'localization_scope.dart';
import 'localizations_delegate.dart';

/// Central accessor for localized validation messages in mk_forms.
///
/// Supports three resolution strategies (ordered by priority):
/// 1. [MkLocalizationScope] in the widget tree.
/// 2. Flutter's standard `Localizations.of<MkFormLocalizations>(context, MkFormLocalizations)`.
/// 3. Global fallback [current] for pure Dart or apps without localization setup.
class MkFormLocalizations {
  const MkFormLocalizations(this.messages);

  /// The active form messages bundle.
  final MkFormMessages messages;

  /// Global fallback validation messages.
  ///
  /// Can be overridden at app startup:
  /// ```dart
  /// void main() {
  ///   MkFormLocalizations.current = MyCustomAppMessages();
  ///   runApp(MyApp());
  /// }
  /// ```
  static MkFormMessages current = const MkDefaultEnglishMessages();

  /// List of built-in supported locales: English ('en') and Spanish ('es').
  static const List<Locale> supportedLocales = [Locale('en'), Locale('es')];

  /// Standard [LocalizationsDelegate] to pass into `MaterialApp.localizationsDelegates`.
  ///
  /// ```dart
  /// MaterialApp(
  ///   localizationsDelegates: [
  ///     MkFormLocalizations.delegate,
  ///     ...GlobalMaterialLocalizations.delegates,
  ///   ],
  ///   ...
  /// )
  /// ```
  static const LocalizationsDelegate<MkFormLocalizations> delegate =
      MkFormLocalizationsDelegate();

  /// Creates a custom [LocalizationsDelegate] with custom per-app language maps.
  ///
  /// ```dart
  /// MkFormLocalizations.createDelegate({
  ///   'fr': MyFrenchMessages(),
  ///   'de': MyGermanMessages(),
  /// })
  /// ```
  static LocalizationsDelegate<MkFormLocalizations> createDelegate(
    Map<String, MkFormMessages> overrides,
  ) => MkFormLocalizationsDelegate(overrides: overrides);

  /// Retrieves the active [MkFormMessages] by context.
  static MkFormMessages of(BuildContext? context) {
    if (context == null) return current;

    // 1. Check MkLocalizationScope first (highest priority)
    final scope = context
        .dependOnInheritedWidgetOfExactType<MkLocalizationScope>();
    if (scope != null) return scope.messages;

    // 2. Check Flutter standard Localizations
    final flutterLoc = Localizations.of<MkFormLocalizations>(
      context,
      MkFormLocalizations,
    );
    if (flutterLoc != null) return flutterLoc.messages;

    // 3. Fallback to global current
    return current;
  }
}
