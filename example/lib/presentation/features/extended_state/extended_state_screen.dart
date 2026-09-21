import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../core/di/injection.dart';
import 'bloc/profile_extras.dart';
import 'bloc/profile_form_bloc.dart';
import 'bloc/profile_form_state.dart';

/// Demonstrates extending [MkFormState] with several independent statuses and
/// typed extra fields.
///
/// - Avatar upload, username check and OTP request run concurrently, each with
///   its own status in [ProfileExtras], a freezed class held by
///   [ProfileFormState].
/// - Each call also stores what it produced in a typed field of that class
///   (`avatarUrl`, `checkedUsername` / `usernameAvailable`, `otpSentTo`) that
///   the UI reads directly.
/// - The submit button is disabled while any of them is running (`isBusy`).
/// - Submitting chains two API calls inside `onSubmit` and reports the running
///   one through `submitStage`.
@RoutePage()
class ExtendedStateScreen extends StatefulWidget {
  const ExtendedStateScreen({super.key, ProfileFormBloc? formBloc})
    : _formBloc = formBloc;

  final ProfileFormBloc? _formBloc;

  @override
  State<ExtendedStateScreen> createState() => _ExtendedStateScreenState();
}

class _ExtendedStateScreenState extends State<ExtendedStateScreen> {
  late final ProfileFormBloc _formBloc;

  @override
  void initState() {
    super.initState();
    _formBloc = widget._formBloc ?? getIt<ProfileFormBloc>();
  }

  @override
  void dispose() {
    unawaited(_formBloc.close());
    super.dispose();
  }

  void _snack(BuildContext context, String message, {Color? color}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Extended Form State')),
      body: MkFormScope.value(
        value: _formBloc,
        child: MkFormListener(
          formBloc: _formBloc,
          onSuccess: (context, response) =>
              _snack(context, 'Profile saved', color: Colors.green),
          onFailure: (context, error) =>
              _snack(context, 'Save failed: $error', color: Colors.red),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const MkTextField(
                name: 'displayName',
                decoration: InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: 16),
              const MkTextField(
                name: 'username',
                decoration: InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 8),
              // Rebuilds when the *displayed* result changes, which also happens
              // when an edit makes a finished check stale.
              MkFormStateBuilder<ProfileFormState>(
                buildWhen: (prev, curr) =>
                    prev.shownUsernameStatus != curr.shownUsernameStatus ||
                    prev.usernameVerdict != curr.usernameVerdict,
                builder: (context, state, bloc) => _CallRow(
                  label: 'Check availability',
                  status: state.shownUsernameStatus,
                  onPressed: () => unawaited(_formBloc.checkUsername()),
                  successText: (_) => state.usernameVerdict == true
                      ? (text: 'Available', color: Colors.green)
                      : (text: 'Taken', color: Colors.orange.shade800),
                ),
              ),
              const SizedBox(height: 16),
              const MkTextField(
                name: 'phone',
                decoration: InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 8),
              MkFormStateBuilder<ProfileFormState>(
                buildWhen: (prev, curr) =>
                    prev.extras.otpStatus != curr.extras.otpStatus ||
                    prev.extras.otpSentTo != curr.extras.otpSentTo,
                builder: (context, state, bloc) => _CallRow(
                  label: 'Send code',
                  status: state.extras.otpStatus,
                  onPressed: () => unawaited(_formBloc.sendOtp()),
                  successText: (_) => (
                    text: 'Code sent to ${state.extras.otpSentTo}',
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              MkFormStateBuilder<ProfileFormState>(
                buildWhen: (prev, curr) =>
                    prev.extras.avatarStatus != curr.extras.avatarStatus ||
                    prev.extras.avatarUrl != curr.extras.avatarUrl,
                builder: (context, state, bloc) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      children: [
                        FilledButton.tonal(
                          onPressed: state.extras.avatarStatus.isSubmitting
                              ? null
                              : () => unawaited(
                                  _formBloc.uploadAvatar('avatar.png'),
                                ),
                          child: const Text('Upload avatar'),
                        ),
                        FilledButton.tonal(
                          onPressed: state.extras.avatarStatus.isSubmitting
                              ? null
                              : () => unawaited(
                                  _formBloc.uploadAvatar('avatar_fail.png'),
                                ),
                          child: const Text('Upload failing avatar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _CallStatusText(
                      state.extras.avatarStatus,
                      successText: (_) => (
                        text: 'Uploaded: ${state.extras.avatarUrl}',
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              MkFormStateBuilder<ProfileFormState>(
                buildWhen: (prev, curr) =>
                    prev.isBusy != curr.isBusy ||
                    prev.extras.submitStage != curr.extras.submitStage,
                builder: (context, state, bloc) => FilledButton(
                  onPressed: state.isBusy
                      ? null
                      : () => unawaited(bloc.submit()),
                  // `submitStage` says which of the submit's two calls is
                  // running; side calls only make the form busy.
                  child: Text(
                    state.extras.submitStage ??
                        (state.isBusy ? 'Working…' : 'Save profile'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Text shown for a successful call, with the colour it should be rendered in.
typedef _SuccessText = ({String text, Color color});

class _CallRow extends StatelessWidget {
  const _CallRow({
    required this.label,
    required this.status,
    required this.onPressed,
    this.successText,
  });

  final String label;
  final MkSubmissionStatus status;
  final VoidCallback onPressed;
  final _SuccessText Function(Object? response)? successText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton.tonal(
          onPressed: status.isSubmitting ? null : onPressed,
          child: Text(label),
        ),
        const SizedBox(width: 12),
        Expanded(child: _CallStatusText(status, successText: successText)),
      ],
    );
  }
}

class _CallStatusText extends StatelessWidget {
  const _CallStatusText(this.status, {this.successText});

  final MkSubmissionStatus status;
  final _SuccessText Function(Object? response)? successText;

  Widget _successLabel(Object? response) {
    final success = successText?.call(response);
    return Text(
      success?.text ?? 'Done',
      style: TextStyle(color: success?.color ?? Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      MkSubmissionIdle() => const SizedBox.shrink(),
      MkSubmissionInProgress() => const Text('Working…'),
      MkSubmissionSuccess(:final response) => _successLabel(response),
      MkSubmissionFailure(:final error) => Text(
        '$error',
        style: const TextStyle(color: Colors.red),
      ),
    };
  }
}
