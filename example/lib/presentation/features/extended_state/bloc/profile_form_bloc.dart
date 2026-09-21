import 'package:injectable/injectable.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../../data/repositories/profile_repository.dart';
import 'profile_form_state.dart';

/// Profile form with three independent API calls plus a multi-call submit.
///
/// Each call updates its own status field and stores what it produced in a
/// typed extra field of [ProfileFormState].
@injectable
class ProfileFormBloc extends MkFormBloc {
  ProfileFormBloc(ProfileRepository repository)
    : this._(repository, {
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
      });

  ProfileFormBloc._(
    this._repository,
    Map<String, MkControlBloc<dynamic>> controls,
  ) : super(
        controls: controls,
        initialState: ProfileFormState.initial(controls),
      );

  final ProfileRepository _repository;

  @override
  ProfileFormState get state => super.state as ProfileFormState;

  String _text(String name) => (values[name] as String?)?.trim() ?? '';

  /// Uploads an avatar; independent of the other calls.
  Future<void> uploadAvatar(String fileName) => _track<String>(
    () => _repository.uploadAvatar(fileName),
    status: (s, status) => s.copyWith(avatarStatus: status),
    onSuccess: (s, url) => s.copyWith(avatarUrl: () => url),
    onFailure: (s) => s.copyWith(avatarUrl: () => null),
  );

  /// Checks whether the typed username is available.
  ///
  /// The verdict is stored together with the username it was checked for, so
  /// [ProfileFormState.usernameVerdict] can ignore it once the field changes.
  Future<void> checkUsername() {
    final username = _text('username');
    return _track<bool>(
      () {
        if (username.isEmpty) throw Exception('Enter a username first');
        return _repository.isUsernameAvailable(username);
      },
      status: (s, status) => s.copyWith(usernameStatus: status),
      onSuccess: (s, available) => s.copyWith(
        checkedUsername: () => username,
        usernameAvailable: () => available,
      ),
      onFailure: (s) => s.copyWith(
        checkedUsername: () => null,
        usernameAvailable: () => null,
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
      status: (s, status) => s.copyWith(otpStatus: status),
      onSuccess: (s, _) => s.copyWith(otpSentTo: () => phone),
      onFailure: (s) => s.copyWith(otpSentTo: () => null),
    );
  }

  /// Runs one tracked call: `submitting`, then `success` or `failure`, with the
  /// extra fields updated on the way out.
  ///
  /// Every transition is applied to the state as it is *when the call
  /// returns*, so calls that overlap only ever touch their own fields.
  Future<void> _track<T>(
    Future<T> Function() call, {
    required ProfileFormState Function(
      ProfileFormState state,
      MkSubmissionStatus status,
    )
    status,
    ProfileFormState Function(ProfileFormState state, T result)? onSuccess,
    ProfileFormState Function(ProfileFormState state)? onFailure,
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
  /// running through [ProfileFormState.submitStage].
  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async {
    try {
      final username = values['username'] as String;
      emit(state.copyWith(submitStage: () => 'Checking username…'));
      final available = await _repository.isUsernameAvailable(username);
      if (!available) {
        throw Exception('Username "$username" is already taken');
      }
      emit(state.copyWith(submitStage: () => 'Saving profile…'));
      return await _repository.saveProfile({
        ...values,
        'avatarUrl': state.avatarUrl,
      });
    } finally {
      emit(state.copyWith(submitStage: () => null));
    }
  }
}
