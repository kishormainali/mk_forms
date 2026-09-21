import 'package:injectable/injectable.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../../data/repositories/profile_repository.dart';
import 'profile_form_state.dart';

/// Profile form with three independent API calls plus a multi-call submit.
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

  /// Uploads an avatar; independent of the other calls.
  Future<void> uploadAvatar(String fileName) => _track(
    () => _repository.uploadAvatar(fileName),
    (status) => state.copyWith(avatarStatus: status),
  );

  /// Checks whether the typed username is available.
  Future<void> checkUsername() => _track(() {
    final username = (values['username'] as String?)?.trim() ?? '';
    if (username.isEmpty) {
      throw Exception('Enter a username first');
    }
    return _repository.isUsernameAvailable(username);
  }, (status) => state.copyWith(usernameStatus: status));

  /// Sends a one-time passcode to the typed phone number.
  Future<void> sendOtp() => _track(() async {
    final phone = (values['phone'] as String?)?.trim() ?? '';
    if (phone.isEmpty) {
      throw Exception('Enter a phone number first');
    }
    await _repository.sendOtp(phone);
    return null;
  }, (status) => state.copyWith(otpStatus: status));

  Future<void> _track(
    Future<Object?> Function() call,
    ProfileFormState Function(MkSubmissionStatus status) apply,
  ) async {
    emit(apply(const MkSubmissionStatus.submitting()));
    try {
      final response = await call();
      emit(apply(MkSubmissionStatus.success(response)));
    } catch (error) {
      emit(apply(MkSubmissionStatus.failure(error)));
    }
  }

  /// A single submit that chains two API calls.
  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async {
    final username = values['username'] as String;
    final available = await _repository.isUsernameAvailable(username);
    if (!available) {
      throw Exception('Username "$username" is already taken');
    }
    final avatar = state.avatarStatus;
    return _repository.saveProfile({
      ...values,
      'avatarUrl': avatar is MkSubmissionSuccess ? avatar.response : null,
    });
  }
}
