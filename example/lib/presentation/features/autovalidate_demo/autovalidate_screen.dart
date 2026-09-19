import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../core/di/injection.dart';
import 'bloc/autovalidate_form_bloc.dart';

/// Interactive showcase demonstrating [AutovalidateMode] behaviors in `mk_forms`.
@RoutePage()
class AutovalidateScreen extends StatefulWidget {
  const AutovalidateScreen({
    super.key,
    AutovalidateFormBloc? formBloc,
  }) : _formBloc = formBloc;

  final AutovalidateFormBloc? _formBloc;

  @override
  State<AutovalidateScreen> createState() => _AutovalidateScreenState();
}

class _AutovalidateScreenState extends State<AutovalidateScreen> {
  late final AutovalidateFormBloc _formBloc;
  AutovalidateMode _currentMode = AutovalidateMode.onUserInteraction;
  bool _overrideEmailMode = false;

  @override
  void initState() {
    super.initState();
    _formBloc = widget._formBloc ?? getIt<AutovalidateFormBloc>();
  }

  @override
  void dispose() {
    unawaited(_formBloc.close());
    super.dispose();
  }

  String _getModeDescription(AutovalidateMode mode) {
    return switch (mode) {
      AutovalidateMode.always =>
        '• Errors are displayed immediately on initial load, even before the user touches any field.',
      AutovalidateMode.onUserInteraction =>
        '• Default mode: Errors stay hidden until the user interacts (blurs/touches) or attempts submission.',
      AutovalidateMode.disabled =>
        '• Errors are suppressed during editing and blur; errors only appear when the form is submitted.',
      AutovalidateMode.onUnfocus =>
        '• Errors appear only after the field loses focus or upon form submission.',
      AutovalidateMode.onUserInteractionIfError =>
        '• Errors only re-validate on interaction if an error already exists.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Autovalidate Modes'),
      ),
      body: MkFormScope(
        formBloc: _formBloc,
        autovalidateMode: _currentMode,
        child: MkFormListener(
          formBloc: _formBloc,
          onSubmitting: (context) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Validating and submitting form...'),
                duration: Duration(milliseconds: 600),
              ),
            );
          },
          onSuccess: (context, response) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Form submitted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          },
          onFailure: (context, error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Submission failed: $error'),
                backgroundColor: Colors.red,
              ),
            );
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'AutovalidateMode Configuration',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a form-wide autovalidation mode below and observe how validation errors are triggered in real-time.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mode selector
                    SegmentedButton<AutovalidateMode>(
                      segments: const [
                        ButtonSegment(
                          value: AutovalidateMode.onUserInteraction,
                          label: Text('onUserInteraction'),
                          icon: Icon(Icons.touch_app_outlined),
                        ),
                        ButtonSegment(
                          value: AutovalidateMode.always,
                          label: Text('always'),
                          icon: Icon(Icons.visibility_outlined),
                        ),
                        ButtonSegment(
                          value: AutovalidateMode.disabled,
                          label: Text('disabled'),
                          icon: Icon(Icons.visibility_off_outlined),
                        ),
                      ],
                      selected: {_currentMode},
                      onSelectionChanged: (selected) {
                        setState(() {
                          _currentMode = selected.first;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Mode description card
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getModeDescription(_currentMode),
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Per-field override toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Email Field Override'),
                      subtitle: Text(
                        _overrideEmailMode
                            ? 'Email is forced to AutovalidateMode.always (ignoring form scope)'
                            : 'Email inherits form scope mode (${_currentMode.name})',
                        style: theme.textTheme.bodySmall,
                      ),
                      value: _overrideEmailMode,
                      onChanged: (val) {
                        setState(() {
                          _overrideEmailMode = val;
                        });
                      },
                    ),
                    const Divider(height: 32),

                    // Form Fields
                    Text(
                      'Sample Form Inputs',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const MkTextField(
                      name: 'username',
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'e.g. alex_dev',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    MkEmailField(
                      name: 'email',
                      autovalidateMode:
                          _overrideEmailMode ? AutovalidateMode.always : null,
                    ),
                    const SizedBox(height: 16),
                    const MkTextField(
                      name: 'bio',
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Tell us a bit about yourself...',
                        prefixIcon: Icon(Icons.notes_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const MkCheckboxField(
                      name: 'agreeTerms',
                      title: Text('I agree to the Terms & Conditions'),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _formBloc.resetForm();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Form reset to pristine state'),
                                  duration: Duration(milliseconds: 600),
                                ),
                              );
                            },
                            icon: const Icon(Icons.restart_alt),
                            label: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _formBloc.fillValidData();
                            },
                            icon: const Icon(Icons.auto_fix_high),
                            label: const Text('Autofill'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<MkFormBloc, MkFormState>(
                      bloc: _formBloc,
                      buildWhen: (prev, curr) =>
                          prev.isSubmitting != curr.isSubmitting,
                      builder: (context, formState) {
                        return FilledButton.icon(
                          onPressed: formState.isSubmitting
                              ? null
                              : () => _formBloc.submit(),
                          icon: formState.isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: const Text('Submit Form'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
