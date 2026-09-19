import 'package:injectable/injectable.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../../data/repositories/user_repository.dart';

/// Form BLoC managing username input with debounced asynchronous availability checks.
@injectable
class UsernameFormBloc extends MkFormBloc {
  UsernameFormBloc(UserRepository userRepository)
      : super(
          controls: {
            'username': MkFieldBloc<String>(
              initialValue: '',
              debounceTime: const Duration(milliseconds: 400),
              validators: [
                MkValidators.required('Username is required'),
                MkValidators.minLength(3, 'Username must be at least 3 characters'),
                (val) {
                  if (val != null && !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(val)) {
                    return 'Only letters, numbers and underscores are allowed';
                  }
                  return null;
                },
              ],
              asyncValidators: [
                (username) async {
                  if (username == null || username.isEmpty) return null;
                  final isAvailable =
                      await userRepository.isUsernameAvailable(username);
                  if (!isAvailable) {
                    return 'Username "$username" is already taken';
                  }
                  return null;
                },
              ],
            ),
          },
        );

  @override
  Future<void> onSubmit(Map<String, dynamic> values) async {}
}
