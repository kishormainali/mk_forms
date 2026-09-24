import 'package:injectable/injectable.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../../data/repositories/profile_repository.dart';
import 'profile_extras.dart';

/// Profile form with three independent API calls plus a multi-call submit.
///
/// Each call updates its own status and stores what it produced in a typed
/// field of [ProfileExtras] — held directly in `MkFormState.extra`, no
/// hand-written state subclass needed.
@injectable
class ProfileFormBloc extends MkFormBloc<ProfileExtras> {
  ProfileFormBloc(this._repository)
    : super(
        controls: {
          'displayName': MkFieldBloc<String>(
            initialValue: '',
            validators: [MkValidators.required('Display name is required')],
          ),
          'username': MkFieldBloc<String>(
            initialValue: '',
            validators: [
              MkValidators.required('Username is required'),
              MkValidators.minLength(3, 'At least 3 characters'),
            ],
          ),
          'phone': MkFieldBloc<String>(
            initialValue: '',
            validators: [MkValidators.required('Phone is required')],
          ),
        },
        initialExtra: () => const ProfileExtras(),
        extraReset: () => const ProfileExtras(),
        isExtraBusy: (e) => e.isBusy,
      );

  final ProfileRepository _repository;

  String _text(String name) => (values[name] as String?)?.trim() ?? '';

  /// Uploads an avatar; independent of the other calls.
  Future<void> uploadAvatar(String fileName) => _track<String>(
    () => _repository.uploadAvatar(fileName),
    status: (s, status) =>
        s.updateExtra((e) => e.copyWith(avatarStatus: status)),
    onSuccess: (s, url) => s.updateExtra((e) => e.copyWith(avatarUrl: url)),
    onFailure: (s) => s.updateExtra((e) => e.copyWith(avatarUrl: null)),
  );

  /// Checks whether the typed username is available.
  ///
  /// The verdict is stored together with the username it was checked for, so
  /// [ProfileFormStateX.usernameVerdict] can ignore it once the field changes.
  Future<void> checkUsername() {
    final username = _text('username');
    return _track<bool>(
      () {
        if (username.isEmpty) throw Exception('Enter a username first');
        return _repository.isUsernameAvailable(username);
      },
      status: (s, status) =>
          s.updateExtra((e) => e.copyWith(usernameStatus: status)),
      onSuccess: (s, available) => s.updateExtra(
        (e) =>
            e.copyWith(checkedUsername: username, usernameAvailable: available),
      ),
      onFailure: (s) => s.updateExtra(
        (e) => e.copyWith(checkedUsername: null, usernameAvailable: null),
      ),
    );
  }

  /// Sends a one-time passcode to the typed phone number.
  Future<void> sendOtp() {
    final phone = _text('phone');
    return _track<void>(
      () {
        if (phone.isEmpty) throw Exception('Enter a phone number first');
        return _repository.sendOtp(phone);
      },
      status: (s, status) =>
          s.updateExtra((e) => e.copyWith(otpStatus: status)),
      onSuccess: (s, _) => s.updateExtra((e) => e.copyWith(otpSentTo: phone)),
      onFailure: (s) => s.updateExtra((e) => e.copyWith(otpSentTo: null)),
    );
  }

  /// Runs one tracked call: `submitting`, then `success` or `failure`, with the
  /// extra fields updated on the way out.
  ///
  /// Every transition is applied to the state as it is *when the call
  /// returns*, so calls that overlap only ever touch their own fields.
  Future<void> _track<T>(
    Future<T> Function() call, {
    required MkFormState<ProfileExtras> Function(
      MkFormState<ProfileExtras> state,
      MkSubmissionStatus status,
    )
    status,
    MkFormState<ProfileExtras> Function(
      MkFormState<ProfileExtras> state,
      T result,
    )?
    onSuccess,
    MkFormState<ProfileExtras> Function(MkFormState<ProfileExtras> state)?
    onFailure,
  }) async {
    emit(status(state, const MkSubmissionStatus.submitting()));
    try {
      final result = await call();
      final updated = onSuccess?.call(state, result) ?? state;
      emit(status(updated, MkSubmissionStatus.success(result)));
    } catch (error) {
      final updated = onFailure?.call(state) ?? state;
      emit(status(updated, MkSubmissionStatus.failure(error)));
    }
  }

  /// A single submit that chains two API calls and reports which one is
  /// running through [ProfileExtras.submitStage].
  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async {
    try {
      final username = values['username'] as String;
      _setStage('Checking username…');
      final available = await _repository.isUsernameAvailable(username);
      if (!available) {
        throw Exception('Username "$username" is already taken');
      }
      _setStage('Saving profile…');
      return await _repository.saveProfile({
        ...values,
        'avatarUrl': state.extra.avatarUrl,
      });
    } finally {
      _setStage(null);
    }
  }

  void _setStage(String? stage) =>
      emit(state.updateExtra((e) => e.copyWith(submitStage: stage)));
}

/// Derived read-only views over [ProfileFormBloc]'s state that used to live
/// as getters on the (now-deleted) `ProfileFormState` subclass. An extension
/// on `MkFormState<T>` is the replacement for "add a computed getter to my
/// form state" now that subclassing is no longer required.
extension ProfileFormStateX on MkFormState<ProfileExtras> {
  /// Availability of the username currently typed in the form: `null` unless
  /// a check finished for exactly this value, so a verdict never outlives an
  /// edit and a check that returns late for an older username is ignored.
  bool? get usernameVerdict {
    final current = (values['username'] as String?)?.trim();
    return extra.checkedUsername != null && extra.checkedUsername == current
        ? extra.usernameAvailable
        : null;
  }

  /// [ProfileExtras.usernameStatus] as it should be shown: a finished check
  /// that no longer matches the typed username is shown as idle.
  MkSubmissionStatus get shownUsernameStatus =>
      extra.usernameStatus.isSuccess && usernameVerdict == null
      ? const MkSubmissionStatus.idle()
      : extra.usernameStatus;
}
