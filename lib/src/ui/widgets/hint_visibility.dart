import 'package:flutter/material.dart';

/// Whether a field's hint should be visible, following the rule a Material
/// [TextField] uses: when the decoration has a label, the hint stays hidden
/// until the label has floated out of the way (focused, or
/// [FloatingLabelBehavior.always]); otherwise it would be drawn on top of the
/// label.
bool mkShouldShowHint(InputDecoration decoration, {required bool isFocused}) {
  final hasLabel = decoration.label != null || decoration.labelText != null;
  if (!hasLabel) return true;
  return switch (decoration.floatingLabelBehavior ??
      FloatingLabelBehavior.auto) {
    FloatingLabelBehavior.always => true,
    FloatingLabelBehavior.auto => isFocused,
    FloatingLabelBehavior.never => false,
  };
}

/// Keeps [child]'s layout space but hides it when [visible] is false, so the
/// field doesn't change height as the hint appears and disappears.
Widget mkHintSlot({required bool visible, required Widget child}) => Visibility(
  visible: visible,
  maintainSize: true,
  maintainAnimation: true,
  maintainState: true,
  child: child,
);
