import 'package:injectable/injectable.dart';
import 'package:mk_forms/mk_forms.dart';

/// Form BLoC managing localized username and email input with default error codes.
@injectable
class I18nDemoFormBloc extends MkFormBloc {
  I18nDemoFormBloc()
    : super(
        controls: {
          'username': MkFieldBloc<String>(
            initialValue: '',
            validators: [MkValidators.required(), MkValidators.minLength(5)],
          ),
          'email': MkFieldBloc<String>(
            initialValue: '',
            validators: [MkValidators.required(), MkValidators.email()],
          ),
        },
      );

  @override
  Future<void> onSubmit(Map<String, dynamic> values) async {}
}
