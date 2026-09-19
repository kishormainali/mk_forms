import 'package:equatable/equatable.dart';

/// Represents the state of a group of form controls.
class MkGroupState extends Equatable {
  const MkGroupState({
    required this.values,
    required this.isValid,
    required this.isValidating,
    required this.isDirty,
    required this.isTouched,
  });

  /// Map of current values for all child controls in this group.
  final Map<String, dynamic> values;

  /// Whether all child controls in this group are valid.
  final bool isValid;

  /// Whether any child control in this group is actively validating asynchronously.
  final bool isValidating;

  /// Whether any child control in this group has been modified from its initial value.
  final bool isDirty;

  /// Whether any child control in this group has been touched.
  final bool isTouched;

  @override
  List<Object?> get props =>
      [values, isValid, isValidating, isDirty, isTouched];
}
