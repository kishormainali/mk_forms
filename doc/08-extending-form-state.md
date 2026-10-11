# 8. Extending Form State

Need more than idle / submitting / success / failure — say an avatar upload and an OTP request alongside the main submit? `MkFormState<T>` has a typed `extra` slot. Reuse `MkSubmissionStatus` per independent call; no state subclass needed.

| Member | Purpose |
|---|---|
| `MkFormState.extra` | Your typed payload (`Object?`/`null` when unused) |
| `updateExtra(fn)` | Shorthand for `copyWith(extra: () => fn(extra))` |
| `isBusy` | `isSubmitting` **or** `isExtraBusy(extra)`; blocks `submit()` and `canSubmit` |
| `reset(...)` | Regenerates `extra` via `extraReset` |
| `MkFormStateBuilder<S>` | Typed builder for `MkFormState<YourExtra>` |

Rules of thumb:

- Give `extra` value equality (`freezed`, `Equatable`, manual `==`).
- Every status must reach a terminal state on every path (use try/catch) or `submit()` is blocked forever.
- If `reset()` can run while calls are in flight, guard late emits (e.g. a generation counter).
- A non-nullable extra type requires `initialState` (or `initialExtra` for step forms).

## Full example — avatar upload + OTP alongside the main submit

To stay dependency-free, the extra here is a hand-written immutable class (swap in `freezed` if you prefer).

```dart
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';

@immutable
class ProfileExtra {
  const ProfileExtra({
    this.avatarStatus = const MkSubmissionStatus.idle(),
    this.otpStatus = const MkSubmissionStatus.idle(),
  });

  final MkSubmissionStatus avatarStatus;
  final MkSubmissionStatus otpStatus;

  bool get isBusy => avatarStatus.isSubmitting || otpStatus.isSubmitting;

  ProfileExtra copyWith({MkSubmissionStatus? avatarStatus, MkSubmissionStatus? otpStatus}) =>
      ProfileExtra(
        avatarStatus: avatarStatus ?? this.avatarStatus,
        otpStatus: otpStatus ?? this.otpStatus,
      );

  @override
  bool operator ==(Object other) =>
      other is ProfileExtra &&
      other.avatarStatus == avatarStatus &&
      other.otpStatus == otpStatus;

  @override
  int get hashCode => Object.hash(avatarStatus, otpStatus);
}

class FakeApi {
  Future<String> uploadAvatar(String path) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return 'https://picsum.photos/200';
  }

  Future<void> sendOtp(String phone) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (phone.length < 8) throw Exception('Invalid phone');
  }

  Future<String> saveProfile(Map<String, dynamic> v) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return 'saved';
  }
}

class ProfileFormBloc extends MkFormBloc<ProfileExtra> {
  ProfileFormBloc(this._api)
      : super(
          controls: {
            'username': MkFieldBloc<String>(
              initialValue: '',
              validators: [MkValidators.required()],
            ),
            'phone': MkFieldBloc<String>(
              initialValue: '',
              validators: [MkValidators.required()],
            ),
          },
          initialExtra: () => const ProfileExtra(),
          extraReset: () => const ProfileExtra(),
          isExtraBusy: (e) => e.isBusy,
        );

  final FakeApi _api;

  Future<void> uploadAvatar(String path) async {
    emit(state.updateExtra(
        (e) => e.copyWith(avatarStatus: const MkSubmissionStatus.submitting())));
    try {
      final url = await _api.uploadAvatar(path);
      emit(state.updateExtra(
          (e) => e.copyWith(avatarStatus: MkSubmissionStatus.success(url))));
    } catch (error) {
      emit(state.updateExtra(
          (e) => e.copyWith(avatarStatus: MkSubmissionStatus.failure(error))));
    }
  }

  Future<void> requestOtp() async {
    emit(state.updateExtra(
        (e) => e.copyWith(otpStatus: const MkSubmissionStatus.submitting())));
    try {
      await _api.sendOtp(field<String>('phone')!.state.value ?? '');
      emit(state.updateExtra(
          (e) => e.copyWith(otpStatus: const MkSubmissionStatus.success('sent'))));
    } catch (error) {
      emit(state.updateExtra(
          (e) => e.copyWith(otpStatus: MkSubmissionStatus.failure(error))));
    }
  }

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) => _api.saveProfile(values);
}

void main() => runApp(const MaterialApp(home: ProfileScreen()));

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MkFormScope(
      create: (_) => ProfileFormBloc(FakeApi()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Builder(builder: (context) {
          final form = context.mkForm as ProfileFormBloc;
          return ListView(padding: const EdgeInsets.all(16), children: [
            // Avatar status, no casts.
            MkFormStateBuilder<MkFormState<ProfileExtra>>(
              buildWhen: (p, c) => p.extra.avatarStatus != c.extra.avatarStatus,
              builder: (context, state, bloc) => switch (state.extra.avatarStatus) {
                MkSubmissionInProgress() => const CircularProgressIndicator(),
                MkSubmissionSuccess(:final response) => Image.network('$response', height: 80),
                MkSubmissionFailure(:final error) => Text('Upload failed: $error'),
                MkSubmissionIdle() => const SizedBox.shrink(),
              },
            ),
            OutlinedButton(
              onPressed: () => form.uploadAvatar('/tmp/me.png'),
              child: const Text('Upload avatar'),
            ),
            const MkTextField(name: 'username', decoration: InputDecoration(labelText: 'Username')),
            const MkTextField(name: 'phone', decoration: InputDecoration(labelText: 'Phone')),
            OutlinedButton(onPressed: form.requestOtp, child: const Text('Send OTP')),
            MkFormStateBuilder<MkFormState<ProfileExtra>>(
              builder: (context, state, bloc) => FilledButton(
                // canSubmit is false while avatar/OTP calls are running.
                onPressed: state.canSubmit ? bloc.submit : null,
                child: Text(state.isBusy ? 'Please wait…' : 'Save'),
              ),
            ),
          ]);
        }),
      ),
    );
  }
}
```

Next: [Step Forms & Wizards](09-step-forms.md).
