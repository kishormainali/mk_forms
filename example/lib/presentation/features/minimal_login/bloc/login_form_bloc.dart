import 'package:injectable/injectable.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../../data/models/auth_credentials.dart';
import '../../../../data/repositories/auth_repository.dart';

/// Form BLoC managing credentials and authentication state.
@injectable
class LoginFormBloc extends MkFormBloc {
  LoginFormBloc(this._authRepository)
    : super(
        controls: {
          'email': MkFieldBloc<String>(
            initialValue: '',
            validators: [
              MkValidators.required('Email is required'),
              MkValidators.email('Please enter a valid email address'),
            ],
          ),
          'password': MkFieldBloc<String>(
            initialValue: '',
            validators: [
              MkValidators.required('Password is required'),
              MkValidators.minLength(
                6,
                'Password must be at least 6 characters',
              ),
            ],
          ),
        },
      );

  final AuthRepository _authRepository;

  @override
  Future<void> onSubmit(Map<String, dynamic> values) async {
    await _authRepository.login(
      AuthCredentials(
        email: values['email'] as String,
        password: values['password'] as String,
      ),
    );
  }
}
