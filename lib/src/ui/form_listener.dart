import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/form_bloc.dart';
import '../core/status.dart';
import 'form_scope.dart';

/// A reactive widget that listens to submission state transitions of an [MkFormBloc].
///
/// Triggers callbacks when form submission is in progress, succeeds, or fails.
class MkFormListener extends StatelessWidget {
  const MkFormListener({
    super.key,
    this.formBloc,
    this.onSubmitting,
    this.onSuccess,
    this.onFailure,
    required this.child,
  });

  /// The form bloc to listen to. If null, it will be looked up via [MkFormScope] or [BlocProvider].
  final MkFormBloc? formBloc;

  /// Invoked when the form submission begins.
  final void Function(BuildContext context)? onSubmitting;

  /// Invoked when the form submission completes successfully.
  final void Function(BuildContext context, Object? response)? onSuccess;

  /// Invoked when the form submission fails.
  final void Function(BuildContext context, Object error)? onFailure;

  /// The child widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bloc = formBloc ?? MkFormScope.of(context);

    return BlocListener<MkFormBloc, MkFormState>(
      bloc: bloc,
      listenWhen: (previous, current) =>
          previous.submissionStatus != current.submissionStatus,
      listener: (context, state) {
        final status = state.submissionStatus;
        if (status.isSubmitting) {
          onSubmitting?.call(context);
        } else if (status.isSuccess) {
          onSuccess?.call(context, (status as MkSubmissionSuccess).response);
        } else if (status.isFailure) {
          onFailure?.call(context, (status as MkSubmissionFailure).error);
        }
      },
      child: child,
    );
  }
}
