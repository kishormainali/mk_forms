import 'package:flutter/widgets.dart';

/// Represents a single selectable option in an [MkRadioGroup].
class MkRadioOption<T> {
  const MkRadioOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.enabled = true,
  });

  /// The value associated with this option.
  final T value;

  /// The label widget or text to display.
  final Widget label;

  /// Optional subtitle widget.
  final Widget? subtitle;

  /// Whether this specific option is enabled.
  final bool enabled;
}

/// Layout mode for presenting radio options.
enum MkRadioLayout {
  /// Vertical list of options.
  vertical,

  /// Horizontal row of options.
  horizontal,

  /// Wrapped flow of options.
  wrap,
}
