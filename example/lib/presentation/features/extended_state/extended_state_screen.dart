import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../core/di/injection.dart';
import 'bloc/profile_form_bloc.dart';
import 'bloc/profile_form_state.dart';

/// Demonstrates extending [MkFormState] with several independent statuses.
///
/// - Avatar upload, username check and OTP request run concurrently, each with
///   its own status field on [ProfileFormState].
/// - The submit button is disabled while any of them is running (`isBusy`).
/// - Submitting chains two API calls inside `onSubmit`.
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
              MkFormStateBuilder<ProfileFormState>(
                buildWhen: (prev, curr) =>
                    prev.usernameStatus != curr.usernameStatus,
                builder: (context, state, bloc) => _CallRow(
                  label: 'Check availability',
                  status: state.usernameStatus,
                  onPressed: () => unawaited(_formBloc.checkUsername()),
                  successText: (response) =>
                      response == true ? 'Available' : 'Taken',
                ),
              ),
              const SizedBox(height: 16),
              const MkTextField(
                name: 'phone',
                decoration: InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 8),
              MkFormStateBuilder<ProfileFormState>(
                buildWhen: (prev, curr) => prev.otpStatus != curr.otpStatus,
                builder: (context, state, bloc) => _CallRow(
                  label: 'Send code',
                  status: state.otpStatus,
                  onPressed: () => unawaited(_formBloc.sendOtp()),
                  successText: (_) => 'Code sent',
                ),
              ),
              const SizedBox(height: 16),
              MkFormStateBuilder<ProfileFormState>(
                buildWhen: (prev, curr) =>
                    prev.avatarStatus != curr.avatarStatus,
                builder: (context, state, bloc) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      children: [
                        FilledButton.tonal(
                          onPressed: state.avatarStatus.isSubmitting
                              ? null
                              : () => unawaited(
                                  _formBloc.uploadAvatar('avatar.png'),
                                ),
                          child: const Text('Upload avatar'),
                        ),
                        FilledButton.tonal(
                          onPressed: state.avatarStatus.isSubmitting
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
                      state.avatarStatus,
                      successText: (response) => 'Uploaded: $response',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              MkFormStateBuilder<ProfileFormState>(
                buildWhen: (prev, curr) => prev.isBusy != curr.isBusy,
                builder: (context, state, bloc) => FilledButton(
                  onPressed: state.isBusy
                      ? null
                      : () => unawaited(bloc.submit()),
                  child: state.isBusy
                      ? const Text('Working…')
                      : const Text('Save profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
  final String Function(Object? response)? successText;

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
  final String Function(Object? response)? successText;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      MkSubmissionIdle() => const SizedBox.shrink(),
      MkSubmissionInProgress() => const Text('Working…'),
      MkSubmissionSuccess(:final response) => Text(
        successText?.call(response) ?? 'Done',
        style: const TextStyle(color: Colors.green),
      ),
      MkSubmissionFailure(:final error) => Text(
        '$error',
        style: const TextStyle(color: Colors.red),
      ),
    };
  }
}
