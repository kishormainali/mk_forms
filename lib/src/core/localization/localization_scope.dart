import 'package:flutter/widgets.dart';
import 'form_messages.dart';

/// InheritedWidget that provides localized validation messages to descendant widgets.
class MkLocalizationScope extends InheritedWidget {
  const MkLocalizationScope({
    super.key,
    required this.messages,
    required super.child,
  });

  /// The active localized messages for descendant form fields.
  final MkFormMessages messages;

  @override
  bool updateShouldNotify(MkLocalizationScope oldWidget) =>
      messages != oldWidget.messages;
}
