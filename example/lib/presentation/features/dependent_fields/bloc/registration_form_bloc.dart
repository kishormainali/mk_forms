import 'package:injectable/injectable.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../data/repositories/user_repository.dart';

/// Form BLoC managing user registration with cross-field dependent validation.
@injectable
class RegistrationFormBloc extends MkFormBloc {
  RegistrationFormBloc(this._userRepository)
      : super(
          controls: _createControls(),
        );

  final UserRepository _userRepository;

  static Map<String, MkControlBloc<dynamic>> _createControls() {
    late final MkFieldBloc<String> passwordBloc;
    late final MkFieldBloc<String> confirmPasswordBloc;

    passwordBloc = MkFieldBloc<String>(
      initialValue: '',
      validators: [
        MkValidators.required('Password is required'),
        MkValidators.minLength(6, 'Password must be at least 6 characters'),
      ],
    );

    confirmPasswordBloc = MkFieldBloc<String>(
      initialValue: '',
      validators: [
        MkValidators.required('Confirm password is required'),
        (confirmVal) {
          if (confirmVal != passwordBloc.value) {
            return 'Passwords do not match';
          }
          return null;
        },
      ],
    );

    // Set up bidirectional dependency so changing either triggers revalidation
    confirmPasswordBloc.addDependency(passwordBloc);
    passwordBloc.addDependency(confirmPasswordBloc);

    return {
      'name': MkFieldBloc<String>(
        initialValue: '',
        validators: [
          MkValidators.required('Full name is required'),
        ],
      ),
      'password': passwordBloc,
      'confirmPassword': confirmPasswordBloc,
    };
  }

  @override
  Future<void> onSubmit(Map<String, dynamic> values) async {
    await _userRepository.registerUser(
      UserProfile(
        name: values['name'] as String,
        password: values['password'] as String,
      ),
    );
  }
}
