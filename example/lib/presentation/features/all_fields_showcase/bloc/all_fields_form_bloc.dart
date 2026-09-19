import 'package:injectable/injectable.dart';
import 'package:mk_forms/mk_forms.dart';

/// Form BLoC providing the complete showcase of all built-in mk_forms fields.
@injectable
class AllFieldsFormBloc extends MkFormBloc {
  AllFieldsFormBloc()
      : super(
          controls: {
            'fullName': MkFieldBloc<String>(
              initialValue: '',
              validators: [MkValidators.required('Name is required')],
            ),
            'email': MkFieldBloc<String>(
              initialValue: '',
              validators: [
                MkValidators.required('Email is required'),
                MkValidators.email('Please enter a valid email'),
              ],
            ),
            'password': MkFieldBloc<String>(
              initialValue: '',
              validators: [
                MkValidators.required('Password is required'),
                MkValidators.minLength(6, 'Must be at least 6 characters'),
              ],
            ),
            'role': MkFieldBloc<String>(
              initialValue: 'developer',
              validators: [MkValidators.required('Please select a role')],
            ),
            'plan': MkFieldBloc<String>(
              initialValue: 'free',
              validators: [MkValidators.required('Plan is required')],
            ),
            'country': MkFieldBloc<String>(
              validators: [MkValidators.required('Country is required')],
            ),
            'technologies': MkFieldBloc<List<String>>(
              initialValue: ['Flutter', 'Dart'],
              validators: [
                (list) {
                  if (list == null || list.isEmpty) {
                    return 'Select at least one technology';
                  }
                  return null;
                },
              ],
            ),
            'agreeTerms': MkFieldBloc<bool>(
              initialValue: false,
              validators: [
                MkValidators.required('You must agree to the terms'),
              ],
            ),
          },
        );

  @override
  Future<void> onSubmit(Map<String, dynamic> values) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }
}
