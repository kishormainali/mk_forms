import 'package:equatable/equatable.dart';
import '../control_bloc.dart';

/// Represents the state of an array of controls.
class MkArrayState<C extends MkControlBloc<dynamic>> extends Equatable {
  const MkArrayState({
    required this.controls,
    required this.values,
    required this.isValid,
    required this.isValidating,
    required this.isDirty,
    required this.isTouched,
  });

  /// List of controls currently in the array.
  final List<C> controls;

  /// Aggregated list of values of all controls.
  final List<dynamic> values;

  /// Whether all controls in the array are valid.
  final bool isValid;

  /// Whether any control is validating asynchronously.
  final bool isValidating;

  /// Whether any control has been modified.
  final bool isDirty;

  /// Whether any control has been touched.
  final bool isTouched;

  int get length => controls.length;
  bool get isEmpty => controls.isEmpty;
  bool get isNotEmpty => controls.isNotEmpty;

  @override
  List<Object?> get props => [
    controls,
    values,
    isValid,
    isValidating,
    isDirty,
    isTouched,
  ];
}
