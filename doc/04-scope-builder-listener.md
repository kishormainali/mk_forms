# 4. `MkFormScope`, `MkFormBuilder`, `MkFormListener`

## `MkFormScope`

Built on `BlocProvider`. It exposes the form bloc (also reachable as `context.read<MkFormBloc>()`) and a default `AutovalidateMode`.

```dart
// Scope creates and closes the bloc.
MkFormScope(
  create: (context) => LoginFormBloc(),
  lazy: true,                                           // default
  autovalidateMode: AutovalidateMode.onUserInteraction, // default
  child: const MyForm(),
)

// Scope exposes an existing bloc and never closes it.
MkFormScope.value(value: myFormBloc, child: const MyForm())
```

### Context extensions (inside a scope)

```dart
context.mkForm.submit();                    // the form bloc
final email = context.mkField<String>('email'); // typed field by name
final mode  = context.mkAutovalidateMode;   // active mode
```

## `MkFormBuilder`

Rebuilds on form-state changes. `formBloc:` is optional (falls back to the scope). Use `buildWhen` to limit rebuilds.

## `MkFormListener`

Reacts to submission transitions (`onSubmitting`, `onSuccess`, `onFailure`) **without** rebuilding its child — use it for navigation, dialogs, snackbars.

## Full example — dialog, snackbar and navigation driven by submission

```dart
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';

class FeedbackFormBloc extends MkFormBloc {
  FeedbackFormBloc()
      : super(controls: {
          'message': MkFieldBloc<String>(
            validators: [MkValidators.required(), MkValidators.minLength(10)],
          ),
        });

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if ((values['message'] as String).contains('fail')) {
      throw Exception('Server rejected the message');
    }
    return 'ticket-1001';
  }
}

void main() => runApp(const MaterialApp(home: FeedbackScreen()));

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MkFormScope(
      create: (_) => FeedbackFormBloc(),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Scaffold(
        appBar: AppBar(title: const Text('Feedback')),
        body: MkFormListener(
          onSubmitting: (context) => showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          ),
          onSuccess: (context, ticket) {
            Navigator.of(context, rootNavigator: true).pop(); // close dialog
            Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => Scaffold(body: Center(child: Text('Thanks! $ticket'))),
            ));
          },
          onFailure: (context, error) {
            Navigator.of(context, rootNavigator: true).pop(); // close dialog
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('$error')));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const MkTextField(
                name: 'message',
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Only rebuilds when validity or submission status changes.
              MkFormBuilder(
                buildWhen: (p, c) =>
                    p.isValid != c.isValid || p.submissionStatus != c.submissionStatus,
                builder: (context, state, form) => FilledButton(
                  onPressed: state.isValid && !state.submissionStatus.isSubmitting
                      ? form.submit
                      : null,
                  child: const Text('Send'),
                ),
              ),
              Builder(
                builder: (context) => TextButton(
                  // context extension
                  onPressed: () => context.mkForm.reset(),
                  child: const Text('Clear'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
```

Type “this will fail” as the message to see the failure path.

Next: [AutovalidateMode](05-autovalidate-mode.md).
