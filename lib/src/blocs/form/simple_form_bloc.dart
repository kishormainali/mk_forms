import 'dart:async';
import 'form_bloc.dart';

/// A lightweight [MkFormBloc] implementation that allows passing
/// an [onSubmit] closure directly without needing to create a custom subclass.
/// Perfect for minimal forms.
class MkSimpleFormBloc extends MkFormBloc {
  MkSimpleFormBloc({
    required super.controls,
    required Future<dynamic> Function(Map<String, dynamic> values) onSubmit,
    void Function(dynamic response)? onSubmitSuccess,
    void Function(Object error)? onSubmitFailure,
  })  : _submitHandler = onSubmit,
        _successHandler = onSubmitSuccess,
        _failureHandler = onSubmitFailure;

  final Future<dynamic> Function(Map<String, dynamic> values) _submitHandler;
  final void Function(dynamic response)? _successHandler;
  final void Function(Object error)? _failureHandler;

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) {
    return _submitHandler(values);
  }

  @override
  void onSubmitSuccess(dynamic response) {
    _successHandler?.call(response);
  }

  @override
  void onSubmitFailure(Object error) {
    _failureHandler?.call(error);
  }
}
